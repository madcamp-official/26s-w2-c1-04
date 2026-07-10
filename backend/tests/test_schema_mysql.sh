#!/usr/bin/env bash
# schema.sql 의 제약이 실제 MySQL 에서 동작하는지 확인한다.
# 트리거·CHECK·에러 우선순위는 SQL 파서 검증으로 절대 잡을 수 없다.
#
#   MYSQL_USER=root MYSQL_PW=root bash backend/tests/test_schema_mysql.sh
#
# schema.sql 이 먼저 적용되어 있어야 한다. 테이블을 비우므로 개발용 DB 에만 쓸 것.

set -uo pipefail

MYSQL_BIN="${MYSQL_BIN:-mysql}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PW="${MYSQL_PW:-root}"
DB="${MYSQL_DB:-memory_pager}"

pass=0; fail=0

q()    { "$MYSQL_BIN" -u "$MYSQL_USER" -p"$MYSQL_PW" -N -B "$DB" -e "$1" 2>&1 | grep -v "insecure"; }
ok()   { pass=$((pass+1)); echo "  ok    $1"; }
bad()  { fail=$((fail+1)); echo "  FAIL  $1  -- $2"; }

expect_errno() {   # label sql errno
  out=$(q "$2")
  if echo "$out" | grep -q "ERROR $3"; then ok "$1"; else bad "$1" "got: ${out:-'(성공해버림)'}"; fi
}
expect_ok() {      # label sql
  out=$(q "$2")
  if echo "$out" | grep -q "^ERROR"; then bad "$1" "$out"; else ok "$1"; fi
}
expect_eq() {      # label sql expected
  out=$(q "$2" | tr -d '\r')
  if [ "$out" = "$3" ]; then ok "$1 (=$3)"; else bad "$1" "expected=$3 got=$out"; fi
}

q "SET FOREIGN_KEY_CHECKS=0;
   TRUNCATE group_members; TRUNCATE \`groups\`; TRUNCATE users; TRUNCATE pets;
   TRUNCATE doodles; TRUNCATE doodle_receipts; TRUNCATE style_models;
   SET FOREIGN_KEY_CHECKS=1;" >/dev/null

echo "--- 예약어 & 기본 삽입 ---"
expect_ok "\`groups\` 는 MySQL 8 예약어 — 백틱으로 쓸 수 있다" \
  "INSERT INTO users (id,display_name) VALUES (1,'A'),(2,'B'),(3,'C');
   INSERT INTO \`groups\` (id,name,invite_code,owner_user_id) VALUES (1,'우리집','K3M9QX2A',1);"

echo
echo "--- 그룹당 2명 (BEFORE INSERT 트리거) ---"
expect_ok    "1번째 멤버" "INSERT INTO group_members (group_id,user_id,role) VALUES (1,1,'owner');"
expect_eq    "member_count 1로 증가" "SELECT member_count FROM \`groups\` WHERE id=1;" "1"
expect_ok    "2번째 멤버" "INSERT INTO group_members (group_id,user_id,role) VALUES (1,2,'member');"
expect_eq    "member_count 2로 증가" "SELECT member_count FROM \`groups\` WHERE id=1;" "2"
expect_errno "3번째 멤버는 트리거가 거부 (1644)" \
  "INSERT INTO group_members (group_id,user_id,role) VALUES (1,3,'member');" 1644

echo
echo "--- 유저당 1그룹 (UNIQUE user_id) ---"
expect_ok    "두 번째 그룹 생성 자체는 가능" \
  "INSERT INTO \`groups\` (id,name,invite_code,owner_user_id) VALUES (2,'딴집','ZZZZ2222',1);"
expect_errno "같은 유저가 두 그룹에 못 들어감 (1062)" \
  "INSERT INTO group_members (group_id,user_id,role) VALUES (2,1,'owner');" 1062

echo
echo "--- 에러 우선순위: 꽉 찬 그룹에서는 트리거가 UNIQUE 를 이긴다 ---"
# 서버가 가입 전에 선검사를 하는 이유. DB 에러만 믿으면 already_member 가
# group_full 로 둔갑한다.
expect_errno "꽉 찬 그룹에 기존 멤버 재가입 -> 1644 (1062 아님)" \
  "INSERT INTO group_members (group_id,user_id,role) VALUES (1,2,'member');" 1644
q "INSERT INTO \`groups\` (id,name,invite_code,owner_user_id) VALUES (3,'빈집','YYYY3333',3);
   INSERT INTO group_members (group_id,user_id,role) VALUES (3,3,'owner');" >/dev/null
expect_errno "안 찬 그룹에 기존 멤버 재가입 -> 1062" \
  "INSERT INTO group_members (group_id,user_id,role) VALUES (3,3,'member');" 1062

echo
echo "--- 탈퇴 시 member_count 감소 (AFTER DELETE 트리거) ---"
expect_ok "멤버 삭제" "DELETE FROM group_members WHERE group_id=1 AND user_id=2;"
expect_eq "member_count 1로 감소" "SELECT member_count FROM \`groups\` WHERE id=1;" "1"

echo
echo "--- CHECK 제약 ---"
expect_errno "member_count=3 은 CHECK 위반 (3819)" \
  "UPDATE \`groups\` SET member_count=3 WHERE id=1;" 3819

echo
echo "--- 사라지기 모드: 확인 1회 멱등 ---"
q "INSERT INTO doodles (id,group_id,sender_id,mode,content_type,created_at)
   VALUES (100,1,1,'ephemeral','drawing',NOW());" >/dev/null
expect_ok    "수신자 최초 확인" "INSERT INTO doodle_receipts (doodle_id,user_id) VALUES (100,2);"
expect_errno "같은 사람의 두 번째 확인은 거부 (1062)" \
  "INSERT INTO doodle_receipts (doodle_id,user_id) VALUES (100,2);" 1062

echo
echo "--- 인덱스 ---"
desc=$(q "SELECT COLLATION FROM information_schema.STATISTICS
          WHERE TABLE_SCHEMA='$DB' AND TABLE_NAME='doodles'
            AND INDEX_NAME='ix_doodles_group_created' AND COLUMN_NAME='created_at';" | tr -d '\r')
[ "$desc" = "D" ] && ok "created_at 이 DESC 인덱스로 생성됨" || bad "DESC 인덱스" "COLLATION=$desc"

echo
echo "=============================="
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
