"""오늘의 질문 (디자인 갭 E-1). docs/API.md '디자인 갭' 절.

매일 커플에게 **같은 질문 하나**가 내려가고 각자 답한다. 질문 텍스트는 DB 에 저장하지 않고
`question_date` 로 코드가 결정한다 — 앱과 서버가 같은 풀·같은 규칙(아래)을 쓰므로 항상 일치한다.
프론트(`lib/screens/home.dart`의 _dailyQuestions)와 이 풀·규칙을 동일하게 유지할 것.
"""

from __future__ import annotations

from datetime import date, datetime

from fastapi import APIRouter
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from .. import realtime, services
from ..deps import CurrentUser, SessionDep
from ..models import QuestionAnswer
from ..schemas import AnswerIn, QuestionOut
from ..services import _KST

router = APIRouter(tags=["questions"])

# 앱과 반드시 동일하게 유지. 규칙: pool[(date - 2026-01-01).days % len].
QUESTION_POOL = [
    "서로 처음 만난 날, 가장 기억에 남는 순간은?",
    "요즘 상대에게 가장 고마웠던 일 하나는?",
    "둘이 같이 가보고 싶은 곳은 어디야?",
    "상대의 웃는 모습 중 제일 좋아하는 순간은?",
    "우리가 함께한 날 중 다시 돌아가고 싶은 하루는?",
    "상대에게 아직 말 못한 사소한 비밀 하나!",
    "다음 기념일엔 뭘 하면서 보내고 싶어?",
]

_EPOCH = date(2026, 1, 1)


def _today_kst() -> date:
    return datetime.now(_KST).date()


def question_for(d: date) -> str:
    return QUESTION_POOL[(d - _EPOCH).days % len(QUESTION_POOL)]


async def _build(session, group_id: int, user_id: int, day: date) -> QuestionOut:
    rows = (
        await session.execute(
            select(QuestionAnswer).where(
                QuestionAnswer.group_id == group_id,
                QuestionAnswer.question_date == day,
            )
        )
    ).scalars().all()
    mine = next((r for r in rows if r.user_id == user_id), None)
    partner = next((r for r in rows if r.user_id != user_id), None)
    return QuestionOut(
        date=day.isoformat(),
        text=question_for(day),
        my_answer=mine.answer if mine else None,
        partner_answered=partner is not None,
        # 내가 답한 뒤에만 상대 답변을 공개(스포일러 방지, 둘 다 답하면 확인 가능) — #6
        partner_answer=(
            partner.answer if (partner is not None and mine is not None) else None
        ),
    )


@router.get("/groups/{group_id}/question/today", response_model=QuestionOut)
async def get_today_question(
    group_id: int, user: CurrentUser, session: SessionDep
) -> QuestionOut:
    await services.require_member(session, user.id, group_id)
    return await _build(session, group_id, user.id, _today_kst())


@router.post("/groups/{group_id}/question/today", response_model=QuestionOut)
async def answer_today_question(
    group_id: int, body: AnswerIn, user: CurrentUser, session: SessionDep
) -> QuestionOut:
    """내 답변 저장(있으면 수정). 재호출로 수정 허용."""
    await services.require_member(session, user.id, group_id)
    day = _today_kst()

    async def _upsert() -> None:
        existing = (
            await session.execute(
                select(QuestionAnswer).where(
                    QuestionAnswer.group_id == group_id,
                    QuestionAnswer.question_date == day,
                    QuestionAnswer.user_id == user.id,
                )
            )
        ).scalar_one_or_none()
        if existing is not None:
            existing.answer = body.answer
        else:
            session.add(
                QuestionAnswer(
                    group_id=group_id,
                    question_date=day,
                    user_id=user.id,
                    answer=body.answer,
                )
            )
        await session.commit()

    # 같은 유저의 더블탭 경합: UNIQUE(group,date,user) 충돌 시 UPDATE 로 재시도.
    try:
        await _upsert()
    except IntegrityError:
        await session.rollback()
        await _upsert()

    # 상대 앱에 "누가 답했다"고 알린다(#6) — 상대가 질문을 다시 받아, 둘 다 답했으면
    # 콜드스타트 없이 바로 상대 답변을 볼 수 있다.
    await realtime.emit_question_answered(group_id, user.id)
    return await _build(session, group_id, user.id, day)
