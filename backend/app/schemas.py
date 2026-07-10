"""요청·응답 스키마. docs/API.md 와 필드가 정확히 같아야 한다.

**ID 는 문자열로 직렬화한다.** 64비트 정수는 JS 의 Number 정밀도를 넘는다 (API.md 0절).
"""

from __future__ import annotations

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


class PetOut(BaseModel):
    id: str
    name: str
    level: int
    exp: int
    coins: int


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


class DoodleOut(BaseModel):
    id: str
    group_id: str
    sender_id: str
    parent_id: str | None
    mode: str
    content_type: str
    photo_url: str | None
    drawing_url: str | None
    # 어떤 유형이든 null 이 되지 않는다 (docs/API.md 4절)
    thumb_url: str
    text_body: str | None
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
