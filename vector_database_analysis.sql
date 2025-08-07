-- PostgreSQL Vector Database Dimensional Analysis
-- Analysis of 1536D vs 1024D embeddings in the LibreChat PKM system
-- Generated: 2025-08-07

-- =====================================================
-- 1. COUNT EMBEDDINGS BY DIMENSION
-- =====================================================

-- Basic dimensional distribution
SELECT 
    vector_dims(embedding) as dimensions,
    COUNT(*) as total_embeddings,
    COUNT(DISTINCT collection_id) as unique_collections,
    COUNT(DISTINCT cmetadata->>'file_id') as unique_files
FROM langchain_pg_embedding 
GROUP BY vector_dims(embedding)
ORDER BY dimensions;

-- =====================================================
-- 2. DETAILED COLLECTION ANALYSIS
-- =====================================================

-- Collection metadata with embedding counts by dimension
SELECT 
    c.name as collection_name,
    c.cmetadata->>'model' as embedding_model,
    c.cmetadata->>'method' as method,
    c.cmetadata->>'dimensions' as declared_dimensions,
    c.cmetadata->>'created_at' as created_at,
    c.cmetadata->>'source' as source,
    c.cmetadata->>'user_id' as user_id,
    vector_dims(e.embedding) as actual_dimensions,
    COUNT(*) as embedding_count,
    MIN(LENGTH(e.document)) as min_doc_length,
    MAX(LENGTH(e.document)) as max_doc_length,
    AVG(LENGTH(e.document))::int as avg_doc_length
FROM langchain_pg_embedding e
JOIN langchain_pg_collection c ON e.collection_id = c.uuid
GROUP BY c.name, c.cmetadata->>'model', c.cmetadata->>'method', 
         c.cmetadata->>'dimensions', c.cmetadata->>'created_at', 
         c.cmetadata->>'source', c.cmetadata->>'user_id', vector_dims(e.embedding)
ORDER BY actual_dimensions, embedding_count DESC;

-- =====================================================
-- 3. SAMPLE CONTENT FOR EACH DIMENSION TYPE
-- =====================================================

-- Sample 1024D embeddings (PKM chunks from Ollama mxbai-embed-large)
SELECT 
    '1024D (Current PKM)' as embedding_type,
    c.name as collection,
    c.cmetadata->>'model' as model,
    c.cmetadata->>'created_at' as created_at,
    LEFT(e.document, 150) as sample_content,
    e.custom_id,
    LENGTH(e.document) as content_length
FROM langchain_pg_embedding e
JOIN langchain_pg_collection c ON e.collection_id = c.uuid
WHERE vector_dims(e.embedding) = 1024
ORDER BY RANDOM()
LIMIT 5;

-- Sample 1536D embeddings (Legacy OpenAI embeddings)
SELECT 
    '1536D (Legacy)' as embedding_type,
    c.name as collection,
    LEFT(e.document, 150) as sample_content,
    e.custom_id,
    LENGTH(e.document) as content_length
FROM langchain_pg_embedding e
JOIN langchain_pg_collection c ON e.collection_id = c.uuid
WHERE vector_dims(e.embedding) = 1536
ORDER BY RANDOM()
LIMIT 5;

-- =====================================================
-- 4. IDENTIFY TEMPORAL PATTERNS
-- =====================================================

-- Creation timeline analysis
SELECT 
    vector_dims(e.embedding) as dimensions,
    c.cmetadata->>'created_at' as collection_created,
    c.cmetadata->>'model' as model,
    c.cmetadata->>'method' as method,
    COUNT(*) as embedding_count
FROM langchain_pg_embedding e
JOIN langchain_pg_collection c ON e.collection_id = c.uuid
GROUP BY vector_dims(e.embedding), c.cmetadata->>'created_at', 
         c.cmetadata->>'model', c.cmetadata->>'method'
ORDER BY c.cmetadata->>'created_at';

-- =====================================================
-- 5. CONTENT ANALYSIS QUERIES
-- =====================================================

-- Analyze content patterns in 1536D embeddings (to identify what they contain)
SELECT 
    'Content Pattern Analysis' as analysis_type,
    vector_dims(embedding) as dimensions,
    COUNT(*) as total_count,
    COUNT(CASE WHEN document LIKE '%Journal%' THEN 1 END) as journal_entries,
    COUNT(CASE WHEN document LIKE '%meeting%' OR document LIKE '%Meeting%' THEN 1 END) as meeting_notes,
    COUNT(CASE WHEN document LIKE '%Source: ../../notes/logs.journal%' THEN 1 END) as log_journals,
    COUNT(CASE WHEN document LIKE '%Source: ../../notes/!-📥-inbox%' THEN 1 END) as inbox_items,
    COUNT(CASE WHEN document LIKE '%Source: ../../notes/📅-daily%' THEN 1 END) as daily_notes
FROM langchain_pg_embedding
WHERE vector_dims(embedding) = 1536
GROUP BY vector_dims(embedding);

-- Analyze content patterns in 1024D embeddings
SELECT 
    'Content Pattern Analysis' as analysis_type,
    vector_dims(embedding) as dimensions,
    COUNT(*) as total_count,
    COUNT(CASE WHEN document LIKE '%Journal%' THEN 1 END) as journal_entries,
    COUNT(CASE WHEN document LIKE '%todo%' OR document LIKE '%TODO%' THEN 1 END) as todo_items,
    COUNT(CASE WHEN document LIKE '%dataview%' THEN 1 END) as dataview_queries,
    COUNT(CASE WHEN custom_id LIKE 'chunk_%' THEN 1 END) as chunk_format
FROM langchain_pg_embedding
WHERE vector_dims(embedding) = 1024
GROUP BY vector_dims(embedding);

-- =====================================================
-- 6. FILE SIZE AND QUALITY COMPARISON
-- =====================================================

-- Compare document quality metrics between dimensions
SELECT 
    vector_dims(embedding) as dimensions,
    COUNT(*) as total_embeddings,
    MIN(LENGTH(document)) as min_content_length,
    MAX(LENGTH(document)) as max_content_length,
    AVG(LENGTH(document))::int as avg_content_length,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY LENGTH(document))::int as median_length,
    COUNT(CASE WHEN LENGTH(document) < 100 THEN 1 END) as very_short_docs,
    COUNT(CASE WHEN LENGTH(document) > 1000 THEN 1 END) as long_docs
FROM langchain_pg_embedding
GROUP BY vector_dims(embedding)
ORDER BY dimensions;

-- =====================================================
-- 7. DISK SPACE ANALYSIS
-- =====================================================

-- Estimate storage usage by dimension
SELECT 
    vector_dims(embedding) as dimensions,
    COUNT(*) as embedding_count,
    pg_size_pretty(
        COUNT(*) * (
            vector_dims(embedding) * 4 + -- Vector storage (float4)
            AVG(LENGTH(document))::int + -- Document text
            100 -- Metadata overhead estimate
        )
    ) as estimated_storage
FROM langchain_pg_embedding
GROUP BY vector_dims(embedding)
ORDER BY dimensions;