-- Wipe all wiki articles and their dependencies.
-- Run with: mysql -u <user> -p <database> < db/wipe_wiki_articles.sql

SET FOREIGN_KEY_CHECKS = 0;

-- 1. PaperTrail version history
DELETE FROM versions WHERE item_type = 'WikiArticle';

-- 2. Cover image attachments (Active Storage)
DELETE FROM active_storage_variant_records
  WHERE blob_id IN (
    SELECT blob_id FROM active_storage_attachments
    WHERE record_type = 'WikiArticle'
  );

DELETE FROM active_storage_blobs
  WHERE id IN (
    SELECT blob_id FROM active_storage_attachments
    WHERE record_type = 'WikiArticle'
  );

DELETE FROM active_storage_attachments WHERE record_type = 'WikiArticle';

-- 3. Collaborator join table
DELETE FROM wiki_article_collaborators;

-- 4. Detach ingredients (wiki_article_id is nullable)
UPDATE ingredients SET wiki_article_id = NULL WHERE wiki_article_id IS NOT NULL;

-- 5. Wiki articles themselves
DELETE FROM wiki_articles;

SET FOREIGN_KEY_CHECKS = 1;
