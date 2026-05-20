"""fix_email_nullable

Revision ID: 6cd2ee563162
Revises: a1b2c3d4e5f6
Create Date: 2026-05-18 13:24:52.141255

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '6cd2ee563162'
down_revision: Union[str, Sequence[str], None] = 'a1b2c3d4e5f6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 把 users 表的 email 字段改成允许为空
    op.alter_column('users', 'email', existing_type=sa.String(length=120), nullable=True)

def downgrade() -> None:
    op.alter_column('users', 'email', existing_type=sa.String(length=120), nullable=False)