-- Feature: Animal registry (searchable list)
-- Params: :tenant_id, :search, :status, :species, :group_id, :limit, :offset
-- Optional params accept NULL. :search matches tag number, name or RFID.
SELECT a.id AS animal_id,
       a.tag_number,
       a.name,
       a.species,
       COALESCE(b.name, a.breed_name_raw)               AS breed,
       a.sex,
       a.date_of_birth,
       date_part('year', age(a.date_of_birth))::int    AS age_years,
       a.status,
       a.origin,
       g.name                                           AS current_group,
       a.rfid_code,
       w.weight_kg                                      AS current_weight_kg,
       a.is_legacy
FROM animals a
LEFT JOIN breeds b ON b.id = a.breed_id
LEFT JOIN groups g ON g.id = a.current_group_id
LEFT JOIN v_animal_current_weight w ON w.animal_id = a.id
WHERE a.tenant_id = :tenant_id
  AND (:search IS NULL
       OR a.tag_number ILIKE '%' || :search || '%'
       OR a.name ILIKE '%' || :search || '%'
       OR a.rfid_code ILIKE '%' || :search || '%')
  AND (:status IS NULL OR a.status = CAST(:status AS animal_status))
  AND (:species IS NULL OR a.species = :species)
  AND (:group_id IS NULL OR a.current_group_id = :group_id)
ORDER BY a.tag_number
LIMIT COALESCE(:limit, 50) OFFSET COALESCE(:offset, 0);
