-- ============================================================================
--  Memory Pager — MySQL 8 스키마
--  근거: docs/ERD.md (v0.3), docs/SPEC.md (v0.3)
--
--  적용:  mysql -u root -p < backend/schema.sql
--
--  주의 1) `groups`는 MySQL 8.0의 예약어(GROUPS)다. 반드시 백틱으로 감싼다.
--  주의 2) 그룹 정원 2명은 CHECK + BEFORE INSERT 트리거로 이중 방어한다.
--          동시 가입 경합은 애플리케이션에서 SELECT ... FOR UPDATE로 잠근다.
--  주의 3) 이 프로젝트는 포트폴리오용이라 보안 하드닝을 하지 않는다.
--          auth_identities.secret_hash도 형식만 갖춘 것이다.
-- ============================================================================

CREATE DATABASE IF NOT EXISTS memory_pager
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE memory_pager;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS question_answers;
DROP TABLE IF EXISTS monthly_reports;
DROP TABLE IF EXISTS pet_items;
DROP TABLE IF EXISTS items;
DROP TABLE IF EXISTS pet_activities;
DROP TABLE IF EXISTS pet_diaries;
DROP TABLE IF EXISTS style_models;
DROP TABLE IF EXISTS pet_likes;
DROP TABLE IF EXISTS pokes;
DROP TABLE IF EXISTS doodle_receipts;
DROP TABLE IF EXISTS doodles;
DROP TABLE IF EXISTS pets;
DROP TABLE IF EXISTS group_members;
DROP TABLE IF EXISTS `groups`;
DROP TABLE IF EXISTS devices;
DROP TABLE IF EXISTS auth_identities;
DROP TABLE IF EXISTS users;
SET FOREIGN_KEY_CHECKS = 1;


-- ----------------------------------------------------------------------------
-- 1. 사람과 인증 수단
--    users는 "사람"이고 절대 바뀌지 않는다. 인증 수단은 auth_identities로
--    분리해 두었으므로, 나중에 카카오 로그인을 붙일 때 같은 user_id에
--    provider='kakao' 행을 하나 더 붙이면 그룹·낙서·펫이 그대로 따라온다.
-- ----------------------------------------------------------------------------

CREATE TABLE users (
    id            BIGINT       NOT NULL AUTO_INCREMENT,
    display_name  VARCHAR(32)  NOT NULL COMMENT '온보딩에서 입력 (ON-1)',
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
                                        ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB;


CREATE TABLE auth_identities (
    id            BIGINT       NOT NULL AUTO_INCREMENT,
    user_id       BIGINT       NOT NULL,
    provider      ENUM('device', 'kakao', 'google', 'apple') NOT NULL,
    provider_uid  VARCHAR(191) NOT NULL COMMENT 'provider 내 고유 식별자',
    secret_hash   CHAR(64)     NULL     COMMENT 'device 토큰 해시. 소셜은 NULL',
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_auth_provider_uid (provider, provider_uid),
    UNIQUE KEY uq_auth_user_provider (user_id, provider),
    CONSTRAINT fk_auth_user FOREIGN KEY (user_id)
        REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB;


CREATE TABLE devices (
    id              BIGINT       NOT NULL AUTO_INCREMENT,
    user_id         BIGINT       NOT NULL,
    fcm_token       VARCHAR(255) NOT NULL COMMENT 'Android 단일 타깃이라 APNs 없음',
    app_version     VARCHAR(20)  NULL,
    last_active_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_devices_fcm_token (fcm_token),
    KEY ix_devices_user (user_id),
    CONSTRAINT fk_devices_user FOREIGN KEY (user_id)
        REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB;


-- ----------------------------------------------------------------------------
-- 2. 그룹 (커플 공간). 정원 2명.
-- ----------------------------------------------------------------------------

CREATE TABLE `groups` (
    id                BIGINT      NOT NULL AUTO_INCREMENT,
    name              VARCHAR(32) NOT NULL,
    invite_code       CHAR(8)     NOT NULL COMMENT '생성 시 자동 발급',
    background_color  CHAR(6)     NOT NULL DEFAULT 'FFFFFF' COMMENT 'hex, # 없이',
    owner_user_id     BIGINT      NOT NULL,
    member_count      TINYINT     NOT NULL DEFAULT 0 COMMENT '정원 2 강제용. 트리거가 관리',
    created_at        DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_groups_invite_code (invite_code),
    KEY ix_groups_owner (owner_user_id),
    CONSTRAINT fk_groups_owner FOREIGN KEY (owner_user_id)
        REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT ck_groups_member_count CHECK (member_count BETWEEN 0 AND 2)
) ENGINE=InnoDB;


CREATE TABLE group_members (
    id         BIGINT      NOT NULL AUTO_INCREMENT,
    group_id   BIGINT      NOT NULL,
    user_id    BIGINT      NOT NULL,
    nickname   VARCHAR(32) NULL COMMENT '상대가 지어준 별명 (ON-4). 2인이라 한 컬럼으로 족하다',
    role       ENUM('owner', 'member') NOT NULL DEFAULT 'member',
    joined_at  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_group_members (group_id, user_id),
    -- 유저당 최대 1그룹. 커플 앱이라 사람은 공간 하나에만 속한다.
    -- 이게 없으면 A그룹 owner 가 B그룹을 새로 만들 수 있고, 그 순간
    -- GET /me 가 어느 그룹을 돌려줄지, 소켓이 어느 룸에 조인할지 정할 수 없다.
    -- 트리거는 group_id 기준으로만 세므로 이걸 막지 못한다.
    UNIQUE KEY uq_group_members_user (user_id),
    CONSTRAINT fk_gm_group FOREIGN KEY (group_id)
        REFERENCES `groups` (id) ON DELETE CASCADE,
    CONSTRAINT fk_gm_user FOREIGN KEY (user_id)
        REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB;


-- ----------------------------------------------------------------------------
-- 3. 펫. 그룹당 1마리.
-- ----------------------------------------------------------------------------

CREATE TABLE pets (
    id          BIGINT      NOT NULL AUTO_INCREMENT,
    group_id    BIGINT      NOT NULL,
    name        VARCHAR(32) NOT NULL,
    level       INT         NOT NULL DEFAULT 1,
    exp         INT         NOT NULL DEFAULT 0,
    coins       INT         NOT NULL DEFAULT 0 COMMENT '펫 스토어 구매용 잔액. 획득 원장은 BACKLOG',
    is_public   BOOLEAN     NOT NULL DEFAULT TRUE COMMENT '다른 그룹이 구경 가능 (EX-1~3)',
    created_at  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_pets_group (group_id),
    CONSTRAINT fk_pets_group FOREIGN KEY (group_id)
        REFERENCES `groups` (id) ON DELETE CASCADE
) ENGINE=InnoDB;


-- ----------------------------------------------------------------------------
-- 4. 낙서와 그 확인 기록
--    사라지기 모드: 수신자가 처음 확인하면 doodle_receipts에 viewed_at이 찍히고
--    서버가 doodles.expires_at = viewed_at + 5초를 세팅한다.
-- ----------------------------------------------------------------------------

CREATE TABLE doodles (
    id            BIGINT       NOT NULL AUTO_INCREMENT,
    group_id      BIGINT       NOT NULL,
    sender_id     BIGINT       NOT NULL,
    parent_id     BIGINT       NULL COMMENT '답장 대상 (RV-1)',
    mode          ENUM('normal', 'ephemeral')          NOT NULL DEFAULT 'normal',
    content_type  ENUM('photo', 'drawing', 'text')     NOT NULL
                  COMMENT '전송 시 앱이 판정해 박는다. 재계산하지 않는다 (RV-3, MR-4)',
    photo_url     VARCHAR(255) NULL,
    drawing_url   VARCHAR(255) NULL,
    stroke_data   JSON         NULL
                  COMMENT '펜 종류·색상·좌표·획별 타임스탬프. 타임스탬프는 그리기 소요 시간용',
    text_body     TEXT         NULL,
    caption       VARCHAR(255) NULL COMMENT '펫이 낙서를 보고 붙이는 한마디(BLIP→EXAONE, 비동기)',
    expires_at    DATETIME(6)  NULL COMMENT 'ephemeral 전용. 최초 확인 + 5초',
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at    DATETIME     NULL COMMENT 'soft delete',
    PRIMARY KEY (id),
    KEY ix_doodles_group_created (group_id, created_at DESC),   -- 사진첩 날짜 정렬 (RV-2)
    KEY ix_doodles_group_type (group_id, content_type),         -- 유형 필터 · LoRA 학습 대상 조회
    KEY ix_doodles_parent (parent_id),                          -- 최고의 낙서 선정 (MR-3, 답장 수)
    KEY ix_doodles_expires (expires_at),                        -- 만료 스윕
    KEY ix_doodles_sender (sender_id),
    CONSTRAINT fk_doodles_group FOREIGN KEY (group_id)
        REFERENCES `groups` (id) ON DELETE CASCADE,
    CONSTRAINT fk_doodles_sender FOREIGN KEY (sender_id)
        REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT fk_doodles_parent FOREIGN KEY (parent_id)
        REFERENCES doodles (id) ON DELETE SET NULL
) ENGINE=InnoDB;


CREATE TABLE doodle_receipts (
    id         BIGINT   NOT NULL AUTO_INCREMENT,
    doodle_id  BIGINT   NOT NULL,
    user_id    BIGINT   NOT NULL,
    viewed_at  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '최초 확인 시각. 갱신하지 않는다',
    PRIMARY KEY (id),
    UNIQUE KEY uq_receipts (doodle_id, user_id),
    KEY ix_receipts_user (user_id),
    CONSTRAINT fk_receipts_doodle FOREIGN KEY (doodle_id)
        REFERENCES doodles (id) ON DELETE CASCADE,
    CONSTRAINT fk_receipts_user FOREIGN KEY (user_id)
        REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB;


CREATE TABLE pokes (
    id            BIGINT   NOT NULL AUTO_INCREMENT,
    group_id      BIGINT   NOT NULL,
    from_user_id  BIGINT   NOT NULL,
    to_user_id    BIGINT   NOT NULL,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY ix_pokes_group_created (group_id, created_at),
    KEY ix_pokes_from (from_user_id),
    KEY ix_pokes_to (to_user_id),
    CONSTRAINT fk_pokes_group FOREIGN KEY (group_id)
        REFERENCES `groups` (id) ON DELETE CASCADE,
    CONSTRAINT fk_pokes_from FOREIGN KEY (from_user_id)
        REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT fk_pokes_to FOREIGN KEY (to_user_id)
        REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB;


-- 오늘의 질문 (디자인 갭 E-1). 질문 텍스트는 코드가 날짜로 결정하고, 여기엔 답변만 남긴다.
-- question_date 는 KST 달력 날짜. 한 사람이 하루에 한 답(UNIQUE), 수정 가능.
CREATE TABLE question_answers (
    id            BIGINT   NOT NULL AUTO_INCREMENT,
    group_id      BIGINT   NOT NULL,
    question_date DATE     NOT NULL,
    user_id       BIGINT   NOT NULL,
    answer        TEXT     NOT NULL,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_question_answers (group_id, question_date, user_id),
    KEY ix_qa_group_date (group_id, question_date),
    CONSTRAINT fk_qa_group FOREIGN KEY (group_id)
        REFERENCES `groups` (id) ON DELETE CASCADE,
    CONSTRAINT fk_qa_user FOREIGN KEY (user_id)
        REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB;


CREATE TABLE pet_likes (
    id          BIGINT   NOT NULL AUTO_INCREMENT,
    pet_id      BIGINT   NOT NULL,
    user_id     BIGINT   NOT NULL,
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_pet_likes (pet_id, user_id),
    KEY ix_pet_likes_user (user_id),
    CONSTRAINT fk_pet_likes_pet FOREIGN KEY (pet_id)
        REFERENCES pets (id) ON DELETE CASCADE,
    CONSTRAINT fk_pet_likes_user FOREIGN KEY (user_id)
        REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB;


-- ----------------------------------------------------------------------------
-- 5. 그림체 모델
--    그룹 생성 시 kind='default', version=0, status='ready' 행을 미리 넣는다.
--    가입 첫날부터 일기가 그려진다. 손그림이 쌓이면 kind='learned'로 LoRA 학습.
-- ----------------------------------------------------------------------------

CREATE TABLE style_models (
    id                    BIGINT       NOT NULL AUTO_INCREMENT,
    group_id              BIGINT       NOT NULL,
    kind                  ENUM('default', 'learned') NOT NULL,
    version               INT          NOT NULL COMMENT 'default는 0',
    status                ENUM('pending', 'training', 'ready', 'failed') NOT NULL DEFAULT 'pending',
    weights_path          VARCHAR(255) NULL COMMENT '프리셋 경로 또는 LoRA 가중치',
    trained_sample_count  INT          NOT NULL DEFAULT 0,
    trained_at            DATETIME     NULL COMMENT 'default는 NULL',
    PRIMARY KEY (id),
    UNIQUE KEY uq_style_group_version (group_id, version),
    KEY ix_style_group_status (group_id, status),
    CONSTRAINT fk_style_group FOREIGN KEY (group_id)
        REFERENCES `groups` (id) ON DELETE CASCADE
) ENGINE=InnoDB;


-- ----------------------------------------------------------------------------
-- 6. 펫의 하루
--    pet_diaries를 먼저 만든다. pet_activities가 diary_id로 참조하기 때문.
--    하루가 끝나면 그날의 활동들이 일기 한 장에 묶인다.
-- ----------------------------------------------------------------------------

CREATE TABLE pet_diaries (
    id              BIGINT       NOT NULL AUTO_INCREMENT,
    pet_id          BIGINT       NOT NULL,
    style_model_id  BIGINT       NOT NULL COMMENT '어느 화풍으로 그렸나. 일기장의 그림체 변천이 여기 남는다',
    entry_date      DATE         NOT NULL,
    image_url       VARCHAR(255) NOT NULL COMMENT 'SD 생성',
    caption         VARCHAR(255) NOT NULL COMMENT 'LLM 생성',
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_diary_pet_date (pet_id, entry_date),           -- 하루 한 장
    KEY ix_diary_style (style_model_id),
    CONSTRAINT fk_diary_pet FOREIGN KEY (pet_id)
        REFERENCES pets (id) ON DELETE CASCADE,
    CONSTRAINT fk_diary_style FOREIGN KEY (style_model_id)
        REFERENCES style_models (id) ON DELETE RESTRICT
) ENGINE=InnoDB;


CREATE TABLE pet_activities (
    id          BIGINT      NOT NULL AUTO_INCREMENT,
    pet_id      BIGINT      NOT NULL,
    diary_id    BIGINT      NULL COMMENT '하루가 끝나면 일기에 묶인다',
    activity    ENUM('eating', 'sleeping', 'walking', 'playing', 'drawing', 'waiting') NOT NULL
                COMMENT '열거값이어야 한다. 이 값으로 SD 프롬프트를 조립한다',
    utterance   VARCHAR(255) NOT NULL COMMENT '쓰다듬으면 하는 말 (PT-1). LLM 생성',
    model       VARCHAR(64)  NOT NULL COMMENT '생성한 LLM 식별자',
    started_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ended_at    DATETIME     NULL COMMENT 'NULL이면 지금 하고 있는 활동',
    PRIMARY KEY (id),
    KEY ix_activities_pet_ended (pet_id, ended_at),   -- 현재 활동 조회. 쓰다듬기는 이걸로 끝난다
    KEY ix_activities_diary (diary_id),
    CONSTRAINT fk_activities_pet FOREIGN KEY (pet_id)
        REFERENCES pets (id) ON DELETE CASCADE,
    CONSTRAINT fk_activities_diary FOREIGN KEY (diary_id)
        REFERENCES pet_diaries (id) ON DELETE SET NULL
) ENGINE=InnoDB;


-- ----------------------------------------------------------------------------
-- 7. 스토어와 아이템 (P2)
-- ----------------------------------------------------------------------------

CREATE TABLE items (
    id           BIGINT      NOT NULL AUTO_INCREMENT,
    category     ENUM('clothes', 'hat', 'accessory', 'furniture', 'background', 'prop') NOT NULL,
    name         VARCHAR(64) NOT NULL,
    price_coins  INT         NOT NULL DEFAULT 0,
    asset_url    VARCHAR(255) NOT NULL,
    PRIMARY KEY (id),
    KEY ix_items_category (category)
) ENGINE=InnoDB;


CREATE TABLE pet_items (
    id           BIGINT   NOT NULL AUTO_INCREMENT,
    pet_id       BIGINT   NOT NULL,
    item_id      BIGINT   NOT NULL,
    is_equipped  BOOLEAN  NOT NULL DEFAULT FALSE,
    pos_x        SMALLINT NULL COMMENT '집 꾸미기 배치 (PT-3)',
    pos_y        SMALLINT NULL,
    acquired_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_pet_items (pet_id, item_id),
    KEY ix_pet_items_item (item_id),
    CONSTRAINT fk_pet_items_pet FOREIGN KEY (pet_id)
        REFERENCES pets (id) ON DELETE CASCADE,
    CONSTRAINT fk_pet_items_item FOREIGN KEY (item_id)
        REFERENCES items (id) ON DELETE CASCADE
) ENGINE=InnoDB;


-- ----------------------------------------------------------------------------
-- 8. 월간 레포트 (스냅샷)
--    사라지기 모드 낙서는 삭제되어 사후 집계가 불가능하고, 월말 푸시 시점에
--    값이 고정되어야 하므로 계산 결과를 저장한다.
-- ----------------------------------------------------------------------------

CREATE TABLE monthly_reports (
    id                  BIGINT   NOT NULL AUTO_INCREMENT,
    group_id            BIGINT   NOT NULL,
    report_month        CHAR(7)  NOT NULL COMMENT 'YYYY-MM. year_month는 함수명과 헷갈려 피했다',
    photo_count         INT      NOT NULL DEFAULT 0,
    drawing_count       INT      NOT NULL DEFAULT 0,
    text_count          INT      NOT NULL DEFAULT 0,
    poke_count          INT      NOT NULL DEFAULT 0,
    dominant_type       ENUM('photo', 'drawing', 'text') NULL,
    best_doodle_id      BIGINT   NULL,
    best_doodle_rule    ENUM('most_replies', 'most_strokes', 'latest') NULL
                        COMMENT '어떤 규칙으로 골랐나. 나중에 vision을 도입하면 값이 늘어난다',
    pet_level_start     INT      NOT NULL DEFAULT 1,
    pet_level_end       INT      NOT NULL DEFAULT 1,
    generated_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_reports_group_month (group_id, report_month),
    KEY ix_reports_best_doodle (best_doodle_id),
    CONSTRAINT fk_reports_group FOREIGN KEY (group_id)
        REFERENCES `groups` (id) ON DELETE CASCADE,
    CONSTRAINT fk_reports_best_doodle FOREIGN KEY (best_doodle_id)
        REFERENCES doodles (id) ON DELETE SET NULL
) ENGINE=InnoDB;


-- ----------------------------------------------------------------------------
-- 9. 그룹 정원 2명 강제
--    CHECK만으로는 "자식 행 2개 이하"를 막을 수 없다. member_count를 트리거로
--    관리하고, BEFORE INSERT에서 3번째 행을 거부한다.
--    동시 가입 경합은 애플리케이션이 groups 행을 FOR UPDATE로 잠가서 막는다.
--
--    ★ 에러 우선순위 (실측: backend/tests/test_schema_mysql.sh)
--      그룹이 이미 꽉 찬 상태에서 기존 멤버가 재가입을 시도하면,
--      BEFORE INSERT 트리거가 UNIQUE(1062)보다 먼저 터져 1644가 난다.
--      즉 DB 에러만 보고 코드를 정하면 already_member 가 group_full 로 둔갑한다.
--      서버가 가입 전에 선검사를 해야 하는 이유다. (app/routers/groups.py)
-- ----------------------------------------------------------------------------

DELIMITER $$

CREATE TRIGGER trg_group_members_before_insert
BEFORE INSERT ON group_members
FOR EACH ROW
BEGIN
    DECLARE current_count INT;
    SELECT COUNT(*) INTO current_count
      FROM group_members
     WHERE group_id = NEW.group_id;

    IF current_count >= 2 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'group is full: a couple space holds at most 2 members';
    END IF;
END$$

CREATE TRIGGER trg_group_members_after_insert
AFTER INSERT ON group_members
FOR EACH ROW
BEGIN
    UPDATE `groups`
       SET member_count = member_count + 1
     WHERE id = NEW.group_id;
END$$

CREATE TRIGGER trg_group_members_after_delete
AFTER DELETE ON group_members
FOR EACH ROW
BEGIN
    UPDATE `groups`
       SET member_count = member_count - 1
     WHERE id = OLD.group_id;
END$$

DELIMITER ;
