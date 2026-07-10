"""월간 레포트. MR-1 ~ MR-4. docs/API.md 6절.

월간 알람(FCM)을 탭하면 이 레포트 뷰어로 들어온다(IA). 선정 규칙은 SPEC 6.5.
"""

from __future__ import annotations

from fastapi import APIRouter
from sqlalchemy import select

from .. import media, services
from ..deps import CurrentUser, SessionDep
from ..errors import ApiError
from ..models import Doodle, DoodleMode, MonthlyReport
from ..schemas import BestDoodleOut, ReportBrief, ReportListOut, ReportOut

router = APIRouter(tags=["reports"])

_ISO = "%Y-%m-%dT%H:%M:%SZ"


async def _report_out(session, report: MonthlyReport) -> ReportOut:
    """레포트 한 행을 최고의 낙서까지 채워 DTO 로 만든다."""
    best = None
    if report.best_doodle_id is not None:
        d = (
            await session.execute(
                select(Doodle).where(
                    Doodle.id == report.best_doodle_id,
                    Doodle.deleted_at.is_(None),
                    # 방어. 생성 단계에서 이미 사라지기 모드를 후보에서 빼지만,
                    # 읽는 쪽에서도 사라지기 낙서 내용이 새지 않도록 한 번 더 막는다.
                    Doodle.mode != DoodleMode.EPHEMERAL,
                )
            )
        ).scalar_one_or_none()
        # 생성 뒤 지워졌으면(정상 낙서는 드물지만) best_doodle 은 null 로 낸다.
        if d is not None:
            best = BestDoodleOut(
                id=str(d.id),
                rule=report.best_doodle_rule.value if report.best_doodle_rule else "latest",
                content_type=d.content_type.value,
                photo_url=d.photo_url,
                drawing_url=d.drawing_url,
                thumb_url=media.thumb_url(d.group_id, d.id),
                text_body=d.text_body,
                created_at=d.created_at.strftime(_ISO),
            )

    return ReportOut(
        report_month=report.report_month,
        photo_count=report.photo_count,
        drawing_count=report.drawing_count,
        text_count=report.text_count,
        poke_count=report.poke_count,
        dominant_type=report.dominant_type.value if report.dominant_type else None,
        pet_level_start=report.pet_level_start,
        pet_level_end=report.pet_level_end,
        best_doodle=best,
    )


async def _load_report(session, group_id: int, report_month: str) -> MonthlyReport:
    report = (
        await session.execute(
            select(MonthlyReport).where(
                MonthlyReport.group_id == group_id,
                MonthlyReport.report_month == report_month,
            )
        )
    ).scalar_one_or_none()
    if report is None:
        raise ApiError(404, "not_found", "그 달 레포트가 없습니다")
    return report


@router.get("/groups/{group_id}/reports", response_model=ReportListOut)
async def list_reports(
    group_id: int, user: CurrentUser, session: SessionDep
) -> ReportListOut:
    await services.require_member(session, user.id, group_id)
    rows = (
        await session.execute(
            select(MonthlyReport)
            .where(MonthlyReport.group_id == group_id)
            .order_by(MonthlyReport.report_month.desc())
        )
    ).scalars().all()
    return ReportListOut(
        items=[
            ReportBrief(
                report_month=r.report_month, generated_at=r.generated_at.strftime(_ISO)
            )
            for r in rows
        ]
    )


@router.get("/groups/{group_id}/reports/{report_month}", response_model=ReportOut)
async def get_report(
    group_id: int, report_month: str, user: CurrentUser, session: SessionDep
) -> ReportOut:
    await services.require_member(session, user.id, group_id)
    services.validate_month(report_month)
    report = await _load_report(session, group_id, report_month)
    return await _report_out(session, report)


@router.post(
    "/groups/{group_id}/reports/{report_month}/generate", response_model=ReportOut
)
async def generate_report(
    group_id: int, report_month: str, user: CurrentUser, session: SessionDep
) -> ReportOut:
    """데모용 수동 트리거. 월 1회 배치가 7일 안엔 안 도니 시연 때 손으로 띄운다."""
    await services.require_member(session, user.id, group_id)
    services.validate_month(report_month)
    await services.generate_report(group_id, report_month)
    # generate_report 는 자기 세션에서 커밋한다. 요청 세션은 require_member 의 SELECT 로
    # 이미 REPEATABLE READ 스냅샷을 잡았으므로, rollback 으로 스냅샷을 버려야 방금 커밋된
    # 레포트가 보인다. 그러지 않으면 갓 만든 레포트를 못 찾아 404 가 난다.
    await session.rollback()
    report = await _load_report(session, group_id, report_month)
    return await _report_out(session, report)
