"""요청·응답 스키마. docs/API.md 와 필드가 정확히 같아야 한다.

**ID 는 문자열로 직렬화한다.** 64비트 정수는 JS 의 Number 정밀도를 넘는다 (API.md 0절).
"""

from __future__ import annotations

import math

from pydantic import BaseModel, Field, field_validator


class UserOut(BaseModel):
    id: str
    display_name: str


class RegisterIn(BaseModel):
    display_name: str = Field(min_length=1, max_length=32)
    device_uid: str = Field(min_length=8, max_length=191)


class RegisterOut(BaseModel):
    token: str
    user: UserOut


class UpdateMeIn(BaseModel):
    display_name: str = Field(min_length=1, max_length=32)


class GroupBrief(BaseModel):
    id: str
    name: str


class MeOut(BaseModel):
    user: UserOut
    group: GroupBrief | None = None


class DeviceIn(BaseModel):
    fcm_token: str = Field(min_length=1, max_length=255)
    app_version: str | None = Field(default=None, max_length=20)


class MemberOut(BaseModel):
    user_id: str
    display_name: str
    nickname: str | None
    role: str


class GroupOut(BaseModel):
    id: str
    name: str
    invite_code: str
    background_color: str
    member_count: int
    members: list[MemberOut]
    # 사귄 날부터의 D-day 를 앱이 계산한다 (디자인 홈 상단). UTC ISO8601.
    created_at: str


class PetOut(BaseModel):
    id: str
    name: str
    level: int
    exp: int
    coins: int


# --- 오늘의 질문 (디자인 갭 E-1) ---


class AnswerIn(BaseModel):
    answer: str = Field(min_length=1, max_length=500)


class QuestionOut(BaseModel):
    date: str  # 'YYYY-MM-DD' (KST)
    text: str
    my_answer: str | None
    # 상대가 오늘 답했는지. 원문은 아직 공개하지 않는다(공개 시점 미확정, API.md 디자인 갭)
    partner_answered: bool


class CreateGroupIn(BaseModel):
    name: str = Field(min_length=1, max_length=32)
    pet_name: str = Field(min_length=1, max_length=32)


class CreateGroupOut(BaseModel):
    group: GroupOut
    pet: PetOut


class JoinGroupIn(BaseModel):
    invite_code: str = Field(min_length=8, max_length=8)

    @field_validator("invite_code")
    @classmethod
    def upper(cls, v: str) -> str:
        return v.upper()


class UpdateGroupIn(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=32)
    background_color: str | None = Field(default=None, pattern=r"^[0-9A-Fa-f]{6}$")


class UpdateNicknameIn(BaseModel):
    nickname: str = Field(min_length=1, max_length=32)


class StrokeCanvas(BaseModel):
    w: int = Field(gt=0, le=8192)
    h: int = Field(gt=0, le=8192)


class Stroke(BaseModel):
    pen: str = Field(min_length=1, max_length=32)
    color: str = Field(pattern=r"^[0-9A-Fa-f]{6}$")
    width: float = Field(gt=0, le=100)
    points: list[tuple[float, float, int]] = Field(min_length=1, max_length=10000)

    @field_validator("points")
    @classmethod
    def valid_points(
        cls, points: list[tuple[float, float, int]]
    ) -> list[tuple[float, float, int]]:
        if any(not math.isfinite(x) or not math.isfinite(y) or elapsed < 0 for x, y, elapsed in points):
            raise ValueError("좌표는 유한수이고 경과 시간은 0 이상이어야 합니다")
        return points


class StrokeData(BaseModel):
    canvas: StrokeCanvas
    duration_ms: int = Field(ge=0, le=86_400_000)
    strokes: list[Stroke] = Field(min_length=1, max_length=5000)


class DoodleOut(BaseModel):
    id: str
    group_id: str
    sender_id: str
    parent_id: str | None
    mode: str
    content_type: str
    photo_url: str | None
    drawing_url: str | None
    # 미열람 사라지기 낙서는 내용을 숨기므로 null이다. 그 외에는 항상 채워진다.
    thumb_url: str | None
    text_body: str | None
    # 펫이 붙인 한마디(GPU 비동기 생성). 아직 생성 전이면 null.
    caption: str | None
    # 아래 둘은 DB 컬럼이 아니라 계산 필드다
    reply_count: int
    viewed_by_me: bool
    expires_at: str | None
    created_at: str


class DoodleListOut(BaseModel):
    items: list[DoodleOut]
    next_before: str | None = None


class ViewOut(BaseModel):
    expires_at: str | None


class PokeIn(BaseModel):
    to_user_id: str


class ActivityOut(BaseModel):
    activity: str
    started_at: str


class EquippedItemOut(BaseModel):
    item_id: str
    category: str
    asset_url: str


class PetDetailOut(BaseModel):
    id: str
    name: str
    level: int
    exp: int
    coins: int
    is_public: bool
    # 펫이 아직 첫 활동을 못 받았으면 null
    current_activity: ActivityOut | None
    equipped_items: list[EquippedItemOut]


class PatOut(BaseModel):
    activity: str
    utterance: str
    exp_gained: int


# ---- 스토어 (#13) ----
class StoreItemOut(BaseModel):
    id: str
    category: str
    name: str
    price_coins: int
    asset_url: str
    owned: bool
    equipped: bool


class StoreListOut(BaseModel):
    coins: int
    items: list[StoreItemOut]


class BuyResultOut(BaseModel):
    item_id: str
    coins: int  # 구매 후 잔액


class EquipIn(BaseModel):
    equipped: bool


class EquipResultOut(BaseModel):
    item_id: str
    equipped: bool


# ---- 이웃집 (#15, EX-1) ----
class NeighborOut(BaseModel):
    group_id: str
    group_name: str
    pet_id: str
    pet_name: str
    pet_level: int
    created_at: str | None  # D-day 계산용
    background_color: str
    likes: int
    liked_by_me: bool


class NeighborResp(BaseModel):
    neighbor: NeighborOut | None  # 다른 공개 그룹이 없으면 null → 앱이 데모를 보여준다


class LikeResultOut(BaseModel):
    pet_id: str
    likes: int
    liked: bool


# ---- 사진첩 AI 큐레이션 (#6) ----
class AlbumOut(BaseModel):
    title: str
    cover_url: str | None
    doodle_ids: list[str]
    count: int


class AlbumsResp(BaseModel):
    albums: list[AlbumOut]  # AI 가 묶은 앨범들. 비어 있으면 앱이 '모두'만 보여준다


class StyleRef(BaseModel):
    kind: str
    version: int


class DiaryOut(BaseModel):
    id: str
    entry_date: str
    image_url: str
    caption: str
    # kind 가 default -> learned 로 바뀌는 날이 "펫이 우리 그림체를 배운 날"이다
    style: StyleRef
    activities: list[str]


class DiaryListOut(BaseModel):
    items: list[DiaryOut]
    next_before: str | None = None


class WidgetOut(BaseModel):
    doodle_id: str | None
    content_type: str | None = None
    # 사라지기 낙서면 null. 위젯에 띄우는 순간을 "확인"으로 칠 수 없다.
    thumb_url: str | None = None
    sender_nickname: str | None = None
    created_at: str | None = None
    is_ephemeral: bool = False


# --- 월간 레포트 (MR-1 ~ MR-4). docs/API.md 6절 ---


class ReportBrief(BaseModel):
    report_month: str  # 'YYYY-MM'
    generated_at: str


class ReportListOut(BaseModel):
    items: list[ReportBrief]


class BestDoodleOut(BaseModel):
    id: str
    # most_replies -> most_strokes -> latest. 나중에 vision 도입 시 값이 는다.
    rule: str
    content_type: str
    # 승자 유형에 따라 셋 중 하나만 채워진다. 앱은 content_type 으로 분기한다.
    photo_url: str | None
    drawing_url: str | None
    thumb_url: str
    text_body: str | None
    created_at: str


class ReportOut(BaseModel):
    report_month: str
    photo_count: int
    drawing_count: int
    text_count: int
    poke_count: int
    # 낙서가 한 장도 없던 달이면 null
    dominant_type: str | None
    pet_level_start: int
    pet_level_end: int
    # 낙서가 없거나 남은 후보가 없으면 null
    best_doodle: BestDoodleOut | None
