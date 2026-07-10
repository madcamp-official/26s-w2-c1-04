"""Memory Pager — SQLAlchemy 2.0 모델.

backend/schema.sql 과 1:1로 대응한다. 스키마를 바꾸면 양쪽을 같이 고쳐야 한다.
근거 문서는 docs/ERD.md (v0.3).

**DDL 의 원본은 schema.sql 이다.** 이 모델로 create_all() 을 부르지 마라.
트리거(그룹 정원 2명 강제)와 DESC 인덱스가 여기에는 표현되어 있지 않다.

**Python 3.9 이상이 필요하다.** `Mapped[list[X]]` 같은 PEP 585 제네릭을
SQLAlchemy 가 런타임에 평가하는데, Python 3.8 에서는 `list[X]` 가 구독 불가라
NameError 로 터진다. Ubuntu 20.04 의 기본 Python 이 3.8 이므로 반드시 올려야 한다.

이 프로젝트는 포트폴리오용이라 보안 하드닝을 하지 않는다.
AuthIdentity.secret_hash 도 형식만 갖춘 것이다.
"""

from __future__ import annotations

import enum
from datetime import date, datetime
from typing import Any, Optional

from sqlalchemy import (
    BigInteger,
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    Integer,
    JSON,
    SmallInteger,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship
from sqlalchemy.sql.elements import quoted_name


class Base(DeclarativeBase):
    pass


def _enum(py_enum: type[enum.Enum], **kw: Any) -> Enum:
    """DDL의 ENUM(...) 과 값이 정확히 일치하도록 강제한다.

    values_callable 을 주지 않으면 SQLAlchemy 가 Enum 의 *이름*을 쓴다.
    우리 DDL 은 소문자 *값*을 쓰므로 반드시 필요하다.
    """
    return Enum(py_enum, values_callable=lambda e: [m.value for m in e], **kw)


# ---------------------------------------------------------------------------
# Enums — schema.sql 의 ENUM 정의와 값이 같아야 한다
# ---------------------------------------------------------------------------


class AuthProvider(str, enum.Enum):
    DEVICE = "device"
    KAKAO = "kakao"
    GOOGLE = "google"
    APPLE = "apple"


class MemberRole(str, enum.Enum):
    OWNER = "owner"
    MEMBER = "member"


class DoodleMode(str, enum.Enum):
    NORMAL = "normal"
    EPHEMERAL = "ephemeral"


class ContentType(str, enum.Enum):
    PHOTO = "photo"
    DRAWING = "drawing"
    TEXT = "text"


class StyleKind(str, enum.Enum):
    DEFAULT = "default"
    LEARNED = "learned"


class StyleStatus(str, enum.Enum):
    PENDING = "pending"
    TRAINING = "training"
    READY = "ready"
    FAILED = "failed"


class PetActivityKind(str, enum.Enum):
    """열거값이어야 한다. 이 값으로 SD 프롬프트를 조립하기 때문에
    LLM 이 자유 문자열을 뱉게 두면 그림을 생성할 수 없다."""

    EATING = "eating"
    SLEEPING = "sleeping"
    WALKING = "walking"
    PLAYING = "playing"
    DRAWING = "drawing"
    WAITING = "waiting"


class ItemCategory(str, enum.Enum):
    CLOTHES = "clothes"
    HAT = "hat"
    ACCESSORY = "accessory"
    FURNITURE = "furniture"
    BACKGROUND = "background"
    PROP = "prop"


class BestDoodleRule(str, enum.Enum):
    MOST_REPLIES = "most_replies"
    MOST_STROKES = "most_strokes"
    LATEST = "latest"


# ---------------------------------------------------------------------------
# 사람과 인증 수단
# ---------------------------------------------------------------------------


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    display_name: Mapped[str] = mapped_column(String(32))
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now()
    )

    identities: Mapped[list[AuthIdentity]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    devices: Mapped[list[Device]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    memberships: Mapped[list[GroupMember]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )


class AuthIdentity(Base):
    """사람(User)과 인증 수단을 분리한다.

    지금은 provider='device' 행 하나만 붙는다. 나중에 카카오 로그인을 추가할 때
    같은 user_id 에 provider='kakao' 행을 하나 더 붙이면 그룹·낙서·펫이 그대로 따라온다.
    익명 토큰을 users 에 직접 박아뒀다면 그 시점에 데이터 마이그레이션이 필요했을 것이다.
    """

    __tablename__ = "auth_identities"
    __table_args__ = (
        UniqueConstraint("provider", "provider_uid", name="uq_auth_provider_uid"),
        UniqueConstraint("user_id", "provider", name="uq_auth_user_provider"),
    )

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    provider: Mapped[AuthProvider] = mapped_column(_enum(AuthProvider))
    provider_uid: Mapped[str] = mapped_column(String(191))
    secret_hash: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    user: Mapped[User] = relationship(back_populates="identities")


class Device(Base):
    __tablename__ = "devices"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    fcm_token: Mapped[str] = mapped_column(String(255), unique=True)
    app_version: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
    last_active_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    user: Mapped[User] = relationship(back_populates="devices")


# ---------------------------------------------------------------------------
# 그룹 (커플 공간). 정원 2명.
# ---------------------------------------------------------------------------


class Group(Base):
    """`groups` 는 MySQL 8 예약어(GROUPS)다. quoted_name 으로 인용을 강제한다."""

    __tablename__ = quoted_name("groups", True)  # type: ignore[assignment]
    __table_args__ = (
        CheckConstraint("member_count BETWEEN 0 AND 2", name="ck_groups_member_count"),
    )

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    name: Mapped[str] = mapped_column(String(32))
    invite_code: Mapped[str] = mapped_column(String(8), unique=True)
    background_color: Mapped[str] = mapped_column(String(6), server_default="FFFFFF")
    owner_user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    member_count: Mapped[int] = mapped_column(SmallInteger, server_default="0")
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    members: Mapped[list[GroupMember]] = relationship(
        back_populates="group", cascade="all, delete-orphan"
    )
    pet: Mapped[Optional[Pet]] = relationship(
        back_populates="group", uselist=False, cascade="all, delete-orphan"
    )
    style_models: Mapped[list[StyleModel]] = relationship(
        back_populates="group", cascade="all, delete-orphan"
    )


class GroupMember(Base):
    """nickname 은 '상대가 지어준 별명'이다.

    2인 그룹에서는 "내가 상대에게 지어준 별명"과 "그룹 내 이 사람의 별명"이 같은 값이라
    (그룹, 부르는이, 불리는이) 3중키 테이블이 필요 없다.
    """

    __tablename__ = "group_members"
    __table_args__ = (UniqueConstraint("group_id", "user_id", name="uq_group_members"),)

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    group_id: Mapped[int] = mapped_column(ForeignKey("groups.id", ondelete="CASCADE"))
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    nickname: Mapped[Optional[str]] = mapped_column(String(32), nullable=True)
    role: Mapped[MemberRole] = mapped_column(_enum(MemberRole), default=MemberRole.MEMBER)
    joined_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    group: Mapped[Group] = relationship(back_populates="members")
    user: Mapped[User] = relationship(back_populates="memberships")


# ---------------------------------------------------------------------------
# 펫
# ---------------------------------------------------------------------------


class Pet(Base):
    __tablename__ = "pets"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    group_id: Mapped[int] = mapped_column(
        ForeignKey("groups.id", ondelete="CASCADE"), unique=True
    )
    name: Mapped[str] = mapped_column(String(32))
    level: Mapped[int] = mapped_column(Integer, server_default="1")
    exp: Mapped[int] = mapped_column(Integer, server_default="0")
    coins: Mapped[int] = mapped_column(Integer, server_default="0")
    is_public: Mapped[bool] = mapped_column(Boolean, server_default="1")
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    group: Mapped[Group] = relationship(back_populates="pet")
    activities: Mapped[list[PetActivity]] = relationship(
        back_populates="pet", cascade="all, delete-orphan"
    )
    diaries: Mapped[list[PetDiary]] = relationship(
        back_populates="pet", cascade="all, delete-orphan"
    )


# ---------------------------------------------------------------------------
# 낙서
# ---------------------------------------------------------------------------


class Doodle(Base):
    __tablename__ = "doodles"
    __table_args__ = (
        Index("ix_doodles_group_created", "group_id", "created_at"),
        Index("ix_doodles_group_type", "group_id", "content_type"),
        Index("ix_doodles_parent", "parent_id"),
        Index("ix_doodles_expires", "expires_at"),
    )

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    group_id: Mapped[int] = mapped_column(ForeignKey("groups.id", ondelete="CASCADE"))
    sender_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    parent_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("doodles.id", ondelete="SET NULL"), nullable=True
    )
    mode: Mapped[DoodleMode] = mapped_column(_enum(DoodleMode), default=DoodleMode.NORMAL)
    content_type: Mapped[ContentType] = mapped_column(_enum(ContentType))
    photo_url: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    drawing_url: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    stroke_data: Mapped[Optional[dict[str, Any]]] = mapped_column(JSON, nullable=True)
    text_body: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    expires_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    deleted_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)

    parent: Mapped[Optional[Doodle]] = relationship(
        remote_side=[id], back_populates="replies"
    )
    replies: Mapped[list[Doodle]] = relationship(back_populates="parent")
    receipts: Mapped[list[DoodleReceipt]] = relationship(
        back_populates="doodle", cascade="all, delete-orphan"
    )


class DoodleReceipt(Base):
    """사라지기 모드의 핵심.

    수신자가 처음 확인하면 viewed_at 이 찍히고, 서버가 doodles.expires_at 을
    viewed_at + 5초로 세팅한다. UNIQUE 제약이 '최초 확인 1회'를 보장하므로
    두 번째 확인은 조용히 무시된다.

    부작용: 체류 시간도 재조회 횟수도 남지 않는다. MR-3 가 쓸 수 있는 행동 신호가
    답장 수 하나뿐인 이유다 (SPEC 7절 ⑤).
    """

    __tablename__ = "doodle_receipts"
    __table_args__ = (UniqueConstraint("doodle_id", "user_id", name="uq_receipts"),)

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    doodle_id: Mapped[int] = mapped_column(ForeignKey("doodles.id", ondelete="CASCADE"))
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    viewed_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    doodle: Mapped[Doodle] = relationship(back_populates="receipts")


class Poke(Base):
    __tablename__ = "pokes"
    __table_args__ = (Index("ix_pokes_group_created", "group_id", "created_at"),)

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    group_id: Mapped[int] = mapped_column(ForeignKey("groups.id", ondelete="CASCADE"))
    from_user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    to_user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())


class PetLike(Base):
    """다른 그룹 펫에 누르는 좋아요 (EX-1). 낙서에 다는 하트가 아니다."""

    __tablename__ = "pet_likes"
    __table_args__ = (UniqueConstraint("pet_id", "user_id", name="uq_pet_likes"),)

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    pet_id: Mapped[int] = mapped_column(ForeignKey("pets.id", ondelete="CASCADE"))
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())


# ---------------------------------------------------------------------------
# 그림체 모델과 펫의 하루
# ---------------------------------------------------------------------------


class StyleModel(Base):
    """그룹 생성 시 kind='default', version=0, status='ready' 행을 미리 넣는다.

    가입 첫날부터 일기가 그려진다. 손그림이 쌓이면 kind='learned' 로 LoRA 를 학습하고,
    ready 가 된 이후의 일기만 새 그림체로 그린다. 과거 일기는 다시 그리지 않는다.
    """

    __tablename__ = "style_models"
    __table_args__ = (
        UniqueConstraint("group_id", "version", name="uq_style_group_version"),
        Index("ix_style_group_status", "group_id", "status"),
    )

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    group_id: Mapped[int] = mapped_column(ForeignKey("groups.id", ondelete="CASCADE"))
    kind: Mapped[StyleKind] = mapped_column(_enum(StyleKind))
    version: Mapped[int] = mapped_column(Integer)
    status: Mapped[StyleStatus] = mapped_column(
        _enum(StyleStatus), default=StyleStatus.PENDING
    )
    weights_path: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    trained_sample_count: Mapped[int] = mapped_column(Integer, server_default="0")
    trained_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)

    group: Mapped[Group] = relationship(back_populates="style_models")
    diaries: Mapped[list[PetDiary]] = relationship(back_populates="style_model")


class PetDiary(Base):
    """하루치 pet_activities 를 그림 한 장 + 캡션으로 묶은 것.

    style_model_id 가 각 일기의 화풍을 기록하므로, 일기장을 넘기면 어느 날부터
    그림체가 바뀌었는지 보인다. 그것이 '펫이 우리 그림체를 배웠다'의 증거다.
    """

    __tablename__ = "pet_diaries"
    __table_args__ = (UniqueConstraint("pet_id", "entry_date", name="uq_diary_pet_date"),)

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    pet_id: Mapped[int] = mapped_column(ForeignKey("pets.id", ondelete="CASCADE"))
    style_model_id: Mapped[int] = mapped_column(
        ForeignKey("style_models.id", ondelete="RESTRICT"), index=True
    )
    entry_date: Mapped[date] = mapped_column(Date)
    image_url: Mapped[str] = mapped_column(String(255))
    caption: Mapped[str] = mapped_column(String(255))
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    pet: Mapped[Pet] = relationship(back_populates="diaries")
    style_model: Mapped[StyleModel] = relationship(back_populates="diaries")
    activities: Mapped[list[PetActivity]] = relationship(back_populates="diary")


class PetActivity(Base):
    """펫이 스스로 사는 하루.

    스케줄러가 하루 몇 차례 LLM 으로 다음 활동과 대사를 만들어 넣는다.
    쓰다듬기(PT-1)는 LLM 을 부르지 않고 ended_at IS NULL 인 현재 활동의
    utterance 를 그대로 돌려준다. 즉 이 테이블 자체가 캐시다.
    """

    __tablename__ = "pet_activities"
    __table_args__ = (Index("ix_activities_pet_ended", "pet_id", "ended_at"),)

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    pet_id: Mapped[int] = mapped_column(ForeignKey("pets.id", ondelete="CASCADE"))
    diary_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("pet_diaries.id", ondelete="SET NULL"), nullable=True, index=True
    )
    activity: Mapped[PetActivityKind] = mapped_column(_enum(PetActivityKind))
    utterance: Mapped[str] = mapped_column(String(255))
    model: Mapped[str] = mapped_column(String(64))
    started_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    ended_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)

    pet: Mapped[Pet] = relationship(back_populates="activities")
    diary: Mapped[Optional[PetDiary]] = relationship(back_populates="activities")


# ---------------------------------------------------------------------------
# 스토어 (P2)
# ---------------------------------------------------------------------------


class Item(Base):
    __tablename__ = "items"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    category: Mapped[ItemCategory] = mapped_column(_enum(ItemCategory), index=True)
    name: Mapped[str] = mapped_column(String(64))
    price_coins: Mapped[int] = mapped_column(Integer, server_default="0")
    asset_url: Mapped[str] = mapped_column(String(255))


class PetItem(Base):
    __tablename__ = "pet_items"
    __table_args__ = (UniqueConstraint("pet_id", "item_id", name="uq_pet_items"),)

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    pet_id: Mapped[int] = mapped_column(ForeignKey("pets.id", ondelete="CASCADE"))
    item_id: Mapped[int] = mapped_column(
        ForeignKey("items.id", ondelete="CASCADE"), index=True
    )
    is_equipped: Mapped[bool] = mapped_column(Boolean, server_default="0")
    pos_x: Mapped[Optional[int]] = mapped_column(SmallInteger, nullable=True)
    pos_y: Mapped[Optional[int]] = mapped_column(SmallInteger, nullable=True)
    acquired_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())


# ---------------------------------------------------------------------------
# 월간 레포트 (스냅샷)
# ---------------------------------------------------------------------------


class MonthlyReport(Base):
    __tablename__ = "monthly_reports"
    __table_args__ = (
        UniqueConstraint("group_id", "report_month", name="uq_reports_group_month"),
    )

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    group_id: Mapped[int] = mapped_column(ForeignKey("groups.id", ondelete="CASCADE"))
    report_month: Mapped[str] = mapped_column(String(7))  # 'YYYY-MM'
    photo_count: Mapped[int] = mapped_column(Integer, server_default="0")
    drawing_count: Mapped[int] = mapped_column(Integer, server_default="0")
    text_count: Mapped[int] = mapped_column(Integer, server_default="0")
    poke_count: Mapped[int] = mapped_column(Integer, server_default="0")
    dominant_type: Mapped[Optional[ContentType]] = mapped_column(
        _enum(ContentType), nullable=True
    )
    best_doodle_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("doodles.id", ondelete="SET NULL"), nullable=True, index=True
    )
    best_doodle_rule: Mapped[Optional[BestDoodleRule]] = mapped_column(
        _enum(BestDoodleRule), nullable=True
    )
    pet_level_start: Mapped[int] = mapped_column(Integer, server_default="1")
    pet_level_end: Mapped[int] = mapped_column(Integer, server_default="1")
    generated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
