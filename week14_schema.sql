-- week14_schema.sql
-- Replace dummy emails in community requests with an instruction to use personal contact info.

UPDATE requests
SET contact_options = (
  SELECT jsonb_agg(
    CASE 
      WHEN (elem->>'value') LIKE '%@goodwillcircle.local' 
        OR (elem->>'value') LIKE '%@gmail.com' 
        OR (elem->>'value') LIKE 'mailto:%' THEN 
        jsonb_set(elem, '{value}', '"Your registered email and phone number will be used to connect."')
      ELSE elem
    END
  )
  FROM jsonb_array_elements(contact_options) AS elem
)
WHERE community_request = true;
