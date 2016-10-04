drop database dynac;
drop tablespace dynac;
create tablespace dynac location '{{ dynac_pg_home }}/data/dynac';
create database dynac tablespace dynac encoding 'UTF8' lc_ctype 'en_US.UTF-8' lc_collate 'en_US.UTF-8' template template0; 

drop database historian;
drop tablespace historian;
create tablespace historian location '/history/historian';
create database historian tablespace historian encoding 'UTF8' lc_ctype 'en_US.UTF-8' lc_collate 'en_US.UTF-8' template template0;

