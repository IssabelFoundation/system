BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS acl_profile_properties
(
       id_profile   INTEGER     NOT NULL,
       property     VARCHAR(32) NOT NULL,
       value        VARCHAR(256),

       PRIMARY KEY (id_profile, property),
       FOREIGN KEY (id_profile) REFERENCES acl_user_profile (id_profile)
);
CREATE TABLE IF NOT EXISTS acl_user_profile
(
       id_profile   INTEGER     NOT NULL,
       id_user      INTEGER     NOT NULL,
       id_resource  INTEGER     NOT NULL,
       profile      VARCHAR(32) NOT NULL,

       PRIMARY KEY (id_profile),
       FOREIGN KEY (id_user)     REFERENCES acl_user(id),
       FOREIGN KEY (id_resource) REFERENCES acl_resource(id)
);
COMMIT;
