ALTER TABLE fridge_items
ADD COLUMN IF NOT EXISTS expiration_date TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_fridge_items_expiration_date
ON fridge_items(expiration_date);
