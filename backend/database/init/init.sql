CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(120) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    nickname VARCHAR(50),
    avatar_url TEXT,
    gender VARCHAR(20) DEFAULT 'unknown',
    birth_date DATE,
    height_cm NUMERIC(5, 2),
    weight_kg NUMERIC(5, 2),
    health_goal VARCHAR(50),
    diet_preference JSONB NOT NULL DEFAULT '[]',
    allergens JSONB NOT NULL DEFAULT '[]',
    profile_json JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS upload_files (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    file_type VARCHAR(30) NOT NULL,
    mime_type VARCHAR(100),
    size_bytes BIGINT,
    scene VARCHAR(50),
    meta_json JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS food_records (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    meal_type VARCHAR(30) NOT NULL,
    record_time TIMESTAMPTZ NOT NULL,
    source_type VARCHAR(30) NOT NULL,
    description TEXT,
    total_calories NUMERIC(10, 2) DEFAULT 0,
    total_protein_g NUMERIC(10, 2) DEFAULT 0,
    total_fat_g NUMERIC(10, 2) DEFAULT 0,
    total_carbohydrate_g NUMERIC(10, 2) DEFAULT 0,
    raw_result_json JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS food_record_items (
    id BIGSERIAL PRIMARY KEY,
    food_record_id BIGINT NOT NULL REFERENCES food_records(id) ON DELETE CASCADE,
    food_name VARCHAR(100) NOT NULL,
    weight_g NUMERIC(10, 2),
    calories NUMERIC(10, 2) DEFAULT 0,
    protein_g NUMERIC(10, 2) DEFAULT 0,
    fat_g NUMERIC(10, 2) DEFAULT 0,
    carbohydrate_g NUMERIC(10, 2) DEFAULT 0,
    confidence NUMERIC(5, 4),
    meta_json JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS fridge_items (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    quantity NUMERIC(10, 2) DEFAULT 1,
    unit VARCHAR(30),
    weight_g NUMERIC(10, 2),
    -- 💡 核心修复点：将 expire_date DATE 改为与 Python 契约完全一致的 expiration_date TIMESTAMPTZ
    expiration_date TIMESTAMPTZ,
    storage_location VARCHAR(50),
    remark TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS recipe_recommendations (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    task_id VARCHAR(100),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    recipe_type VARCHAR(50),
    ingredients_json JSONB NOT NULL DEFAULT '[]',
    steps_json JSONB NOT NULL DEFAULT '[]',
    nutrition_json JSONB NOT NULL DEFAULT '{}',
    score NUMERIC(6, 4),
    reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS health_feedbacks (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    food_record_id BIGINT REFERENCES food_records(id) ON DELETE SET NULL,
    feedback_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    bloating_level INT DEFAULT 0,
    fatigue_level INT DEFAULT 0,
    mood VARCHAR(50),
    digestive_note TEXT,
    extra_symptoms JSONB NOT NULL DEFAULT '[]',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS community_posts (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    food_record_id BIGINT REFERENCES food_records(id) ON DELETE SET NULL,
    title VARCHAR(200) NOT NULL,
    content TEXT,
    image_urls JSONB NOT NULL DEFAULT '[]',
    tags JSONB NOT NULL DEFAULT '[]',
    visibility VARCHAR(30) DEFAULT 'public',
    like_count INT NOT NULL DEFAULT 0,
    comment_count INT NOT NULL DEFAULT 0,
    fork_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS post_comments (
    id BIGSERIAL PRIMARY KEY,
    post_id BIGINT NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS post_likes (
    id BIGSERIAL PRIMARY KEY,
    post_id BIGINT NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_post_likes_post_user UNIQUE (post_id, user_id)
);

CREATE TABLE IF NOT EXISTS post_forks (
    id BIGSERIAL PRIMARY KEY,
    post_id BIGINT NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_date DATE,
    target_meal_type VARCHAR(30),
    new_plan_id BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS taste_vectors (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    vector_json JSONB NOT NULL DEFAULT '[]',
    tags JSONB NOT NULL DEFAULT '[]',
    updated_source VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ai_tasks (
    id BIGSERIAL PRIMARY KEY,
    task_id VARCHAR(100) UNIQUE NOT NULL,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    task_type VARCHAR(50) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'pending',
    input_json JSONB NOT NULL DEFAULT '{}',
    result_json JSONB NOT NULL DEFAULT '{}',
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ai_analysis_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    task_id VARCHAR(100),
    provider VARCHAR(50),
    model_name VARCHAR(100),
    prompt_summary TEXT,
    input_json JSONB NOT NULL DEFAULT '{}',
    output_json JSONB NOT NULL DEFAULT '{}',
    latency_ms INT,
    success BOOLEAN DEFAULT TRUE,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_food_records_user_id ON food_records(user_id);
CREATE INDEX IF NOT EXISTS idx_food_records_record_time ON food_records(record_time);
CREATE INDEX IF NOT EXISTS idx_food_records_user_time ON food_records(user_id, record_time);

CREATE INDEX IF NOT EXISTS idx_food_record_items_record_id ON food_record_items(food_record_id);

CREATE INDEX IF NOT EXISTS idx_fridge_items_user_id ON fridge_items(user_id);
-- 💡 同步修复索引字段名
CREATE INDEX IF NOT EXISTS idx_fridge_items_expiration_date ON fridge_items(expiration_date);

CREATE INDEX IF NOT EXISTS idx_health_feedbacks_user_id ON health_feedbacks(user_id);
CREATE INDEX IF NOT EXISTS idx_health_feedbacks_food_record_id ON health_feedbacks(food_record_id);

CREATE INDEX IF NOT EXISTS idx_community_posts_user_id ON community_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_community_posts_created_at ON community_posts(created_at);

CREATE INDEX IF NOT EXISTS idx_post_comments_post_id ON post_comments(post_id);
CREATE INDEX IF NOT EXISTS idx_post_likes_post_id ON post_likes(post_id);
CREATE INDEX IF NOT EXISTS idx_post_forks_post_id ON post_forks(post_id);

CREATE INDEX IF NOT EXISTS idx_ai_tasks_task_id ON ai_tasks(task_id);
CREATE INDEX IF NOT EXISTS idx_ai_tasks_user_id ON ai_tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_tasks_status ON ai_tasks(status);

INSERT INTO users (
    username,
    email,
    password_hash,
    nickname,
    gender,
    height_cm,
    weight_kg,
    health_goal,
    diet_preference,
    allergens
)
VALUES (
    'demo_user',
    'demo@example.com',
    '$2b$12$L...这里是你原来想要替换的密码哈希...', 
    '演示用户',
    'unknown',
    170,
    60,
    'keep_fit',
    '["high_protein", "low_sugar"]',
    '[]'
)
ON CONFLICT (username) DO NOTHING;