WITH client_base AS (                -- Q04 / 47
    SELECT  ECI,
            UCN,
            NVL(shortName, name)          AS client_name,
            creditUltimateParentECI       AS parent_eci,
            primaryCRUGroupIdentifier     AS cru_group,
            primaryCRUSectorIdentifier    AS cru_sector
    FROM    "REFERENCE DATA".Client.Restricted."v_creditClientConsumable"
    WHERE   CIT_EOP_CONTEXT_KEY = ?
      AND   ECI IN (?)                   -- client list
),
family_counts AS (                     -- Q12 / 39
    SELECT  creditUltimateParentECI AS parent_eci,
            COUNT(*)                AS num_clients_in_family
    FROM    "REFERENCE DATA".Client.Restricted."v_creditClientConsumable"
    WHERE   CIT_EOP_CONTEXT_KEY = ?
    GROUP BY creditUltimateParentECI
),
c_flag AS (                            -- Q16 / 17
    SELECT  ECI,
            MAX(effectiveToDate) AS c_flag_expiry
    FROM    "REFERENCE DATA".Client.Restricted."v_clientCreditFlag"
    WHERE   creditflagIdentifier = 'C'
    GROUP   BY ECI
),
casid AS (                             -- Q28
    SELECT  ECI,
            MAX(CASID)        AS casid
    FROM    "REFERENCE DATA".Client.Restricted."v_creditClient"
    WHERE   effectiveToDate > CURRENT_DATE
    GROUP   BY ECI
),
iid AS (                               -- Q25 / 26
    SELECT  ECI,
            MAX(clientInternalIdentifier) AS client_internal_id
    FROM    "REFERENCE DATA".Client.Unrestricted."v_clientECI"
    WHERE   CURRENT_DATE BETWEEN effectiveFromDate AND effectiveToDate
    GROUP   BY ECI
),
fam_names AS (                         -- Q18 / 27 / 38
    SELECT  ECI,
            LISTAGG(DISTINCT familyName, ',') AS family_names
    FROM    "REFERENCE DATA".Client.Restricted."v_clientHierarchy"
    WHERE   CURRENT_DATE BETWEEN effectiveFromDate AND effectiveToDate
    GROUP   BY ECI
)
SELECT  cb.eci                         AS client_oid,
        cb.ucn                         AS client_ucn,
        cb.client_name,
        cb.cru_group,
        cb.cru_sector,
        iid.client_internal_id,
        casid.casid,
        cb.parent_eci                  AS parent_oid,
        fc.num_clients_in_family,
        fn.family_names,
        cf.c_flag_expiry
FROM        client_base   cb
LEFT JOIN   family_counts fc   ON fc.parent_eci = cb.parent_eci
LEFT JOIN   c_flag       cf    ON cf.eci        = cb.eci
LEFT JOIN   casid        ca    ON ca.eci        = cb.eci
LEFT JOIN   iid          iid   ON iid.eci       = cb.eci
LEFT JOIN   fam_names    fn    ON fn.eci        = cb.eci;
