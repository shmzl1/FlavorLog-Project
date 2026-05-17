"""add phone to users

Revision ID: a1b2c3d4e5f6
Revises: 725b06848faf
Create Date: 2026-05-17 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, Sequence[str], None] = '725b06848faf'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        'users',
        sa.Column('phone', sa.String(20), nullable=True),
    )
    op.create_unique_constraint('uq_users_phone', 'users', ['phone'])
    op.create_index('ix_users_phone', 'users', ['phone'], unique=True)


def downgrade() -> None:
    op.drop_index('ix_users_phone', table_name='users')
    op.drop_constraint('uq_users_phone', 'users', type_='unique')
    op.drop_column('users', 'phone')
