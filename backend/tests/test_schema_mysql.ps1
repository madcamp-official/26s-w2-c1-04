param(
    [string]$MysqlBin = (Get-Command mysql -ErrorAction Stop).Source,
    [string]$UserName = "root",
    [string]$Password = "root",
    [string]$Database = "memory_pager"
)

$passCount = 0
$failCount = 0

function Invoke-TestSql([string]$Sql) {
    $raw = & $MysqlBin "-u$UserName" "-p$Password" --default-character-set=utf8mb4 -N -B $Database -e $Sql 2>&1
    $code = $LASTEXITCODE
    $clean = @($raw | Where-Object { $_ -notmatch "insecure" }) -join "`n"
    return [PSCustomObject]@{ Code = $code; Output = $clean.Trim() }
}

function Pass([string]$Label) {
    $script:passCount += 1
    Write-Output "  ok    $Label"
}

function Fail([string]$Label, [string]$Detail) {
    $script:failCount += 1
    Write-Output "  FAIL  $Label -- $Detail"
}

function Expect-Ok([string]$Label, [string]$Sql) {
    $result = Invoke-TestSql $Sql
    if ($result.Code -eq 0) { Pass $Label } else { Fail $Label $result.Output }
}

function Expect-Error([string]$Label, [string]$Sql, [int]$Errno) {
    $result = Invoke-TestSql $Sql
    if ($result.Code -ne 0 -and $result.Output -match "ERROR $Errno") {
        Pass $Label
    } else {
        Fail $Label "expected ERROR $Errno, got: $($result.Output)"
    }
}

function Expect-Equal([string]$Label, [string]$Sql, [string]$Expected) {
    $result = Invoke-TestSql $Sql
    if ($result.Code -eq 0 -and $result.Output -eq $Expected) {
        Pass "$Label (=$Expected)"
    } else {
        Fail $Label "expected=$Expected got=$($result.Output)"
    }
}

[void](Invoke-TestSql @'
SET FOREIGN_KEY_CHECKS=0;
TRUNCATE group_members; TRUNCATE `groups`; TRUNCATE users; TRUNCATE pets;
TRUNCATE doodles; TRUNCATE doodle_receipts; TRUNCATE style_models;
SET FOREIGN_KEY_CHECKS=1;
'@)

Expect-Ok "예약어 groups와 기본 삽입" @'
INSERT INTO users (id,display_name) VALUES (1,'A'),(2,'B'),(3,'C');
INSERT INTO `groups` (id,name,invite_code,owner_user_id) VALUES (1,'우리집','K3M9QX2A',1);
'@

Expect-Ok "1번째 멤버" "INSERT INTO group_members (group_id,user_id,role) VALUES (1,1,'owner');"
Expect-Equal "member_count 1로 증가" "SELECT member_count FROM ``groups`` WHERE id=1;" "1"
Expect-Ok "2번째 멤버" "INSERT INTO group_members (group_id,user_id,role) VALUES (1,2,'member');"
Expect-Equal "member_count 2로 증가" "SELECT member_count FROM ``groups`` WHERE id=1;" "2"
Expect-Error "3번째 멤버 거부" "INSERT INTO group_members (group_id,user_id,role) VALUES (1,3,'member');" 1644

Expect-Ok "두 번째 그룹 생성" "INSERT INTO ``groups`` (id,name,invite_code,owner_user_id) VALUES (2,'딴집','ZZZZ2222',1);"
Expect-Error "유저당 1그룹" "INSERT INTO group_members (group_id,user_id,role) VALUES (2,1,'owner');" 1062
Expect-Error "꽉 찬 그룹 에러 우선순위" "INSERT INTO group_members (group_id,user_id,role) VALUES (1,2,'member');" 1644

Expect-Ok "빈 그룹과 소유자 준비" @'
INSERT INTO `groups` (id,name,invite_code,owner_user_id) VALUES (3,'빈집','YYYY3333',3);
INSERT INTO group_members (group_id,user_id,role) VALUES (3,3,'owner');
'@
Expect-Error "안 찬 그룹 재가입은 UNIQUE" "INSERT INTO group_members (group_id,user_id,role) VALUES (3,3,'member');" 1062

Expect-Ok "멤버 삭제" "DELETE FROM group_members WHERE group_id=1 AND user_id=2;"
Expect-Equal "member_count 1로 감소" "SELECT member_count FROM ``groups`` WHERE id=1;" "1"
Expect-Error "member_count CHECK" "UPDATE ``groups`` SET member_count=3 WHERE id=1;" 3819

Expect-Ok "사라지기 낙서와 최초 receipt" @'
INSERT INTO doodles (id,group_id,sender_id,mode,content_type,created_at)
VALUES (100,1,1,'ephemeral','drawing',NOW());
INSERT INTO doodle_receipts (doodle_id,user_id) VALUES (100,2);
'@
Expect-Error "receipt 최초 확인 1회" "INSERT INTO doodle_receipts (doodle_id,user_id) VALUES (100,2);" 1062
Expect-Equal "expires_at 마이크로초 정밀도" "SELECT DATETIME_PRECISION FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='doodles' AND COLUMN_NAME='expires_at';" "6"
Expect-Equal "viewed_at 마이크로초 정밀도" "SELECT DATETIME_PRECISION FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='doodle_receipts' AND COLUMN_NAME='viewed_at';" "6"

$indexResult = Invoke-TestSql "SELECT COLLATION FROM information_schema.STATISTICS WHERE TABLE_SCHEMA='$Database' AND TABLE_NAME='doodles' AND INDEX_NAME='ix_doodles_group_created' AND COLUMN_NAME='created_at';"
if ($indexResult.Output -eq "D") { Pass "created_at DESC 인덱스" } else { Fail "created_at DESC 인덱스" $indexResult.Output }

Write-Output ""
Write-Output "$passCount passed, $failCount failed"
if ($failCount -gt 0) { exit 1 }
