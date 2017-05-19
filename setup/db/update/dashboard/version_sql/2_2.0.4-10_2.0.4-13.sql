ALTER TABLE activated_applet_by_user ADD COLUMN username varchar(100);

UPDATE activated_applet_by_user SET username='admin';

