drop table if exists game_field;
create table game_field
(
 id serial,
 a varchar(1) default '.',
 b varchar(1) default '.',
 c varchar(1) default '.',
 d varchar(1) default '.',
 e varchar(1) default '.',
 f varchar(1) default '.',
 g varchar(1) default '.',
 h varchar(1) default '.',
 i varchar(1) default '.',
 j varchar(1) default '.',
);

insert into game_field (id) values (0), (1), (2), (3), (4), (5), (6), (7), (8), (9);

drop table if exists game_event;
create table game_event
(
 id timestamp default now(),
 player text not null,
 event text not null,
 cell text default null
);

drop table if exists game_ships;
create table game_ships
(
 id serial,
 start_cell text,
 end_cell text,
 length int,
 health int
);

create or replace function game_create() returns text
language plpgsql
as $$
declare
	game_id text;
begin
	select random_text_simple(10) into game_id;

	execute 'create table game_field_' || game_id || '_a as select * from game_field;';
	execute 'create table game_field_' || game_id || '_b as select * from game_field;';
	execute 'create table game_ships_' || game_id || '_a as select * from game_ships;';
	execute 'create table game_ships_' || game_id || '_b as select * from game_ships;';
	execute 'create table game_event_' || game_id || ' as table game_event with no data;';
	execute 'create table game_event_' || game_id || ' (id, player, event) values (now(), ''a'', ''connected'');';

	return game_id;

end
$$;

create or replace procedure game_connect(game_id text)
language plpgsql
as $$
declare
	table_exists bool;
begin
	exicute 'SELECT EXISTS(SELECT FROM pg_tables WHERE schemname = ''public'' AND tablename = lower(''game_event_' ||game_id||'''));' into table_exists;
	if table_exists = false then
		raise exeption 'No such game!';
	end if;
	commit;
	execute 'insert into game_event_' || game_id || ' (id, player, event) values (now(), ''b'', ''connected'');';
	commit;
end
$$;

create or replace procedure game_wait_for_opponent(game_id text)
language plpgsql
as $$
declare
	c int;
begin
	loop
		execute 'select count(*) from game_event_' || game_id || 'where event = ''connected'' and player = ''b'';' into c;
		if c > 0 then
			exit;
		end if;
		perform pg_sleep(1);
	end loop;
end;
$$;

create or replace procedure game_wait_for_ready(game_id text)
language plpgsql
as $$
declare
	c int;
begin
	loop
		execute 'select count(*) from game_event_' || game_id || 'where event = '';' into c;
		if c = 2 then
			exit;
		end if;
		perform pg_sleep(1);
	end loop;
end;
$$
