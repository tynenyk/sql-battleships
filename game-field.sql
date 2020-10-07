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

create or replace procedure game_print_single_field(game_id text, player text)
language plpgsql
as $$
declare
	r record;
	ships int;
	additinal text := '';
begin
	raise info '.. A B C D E F G H I J';
	for r in execute 'select * from game_field_' || game_id || '_' || player || 'order by id' loop
		select '' into additinal;
		if r.id = 3 then
			execute format('select count(*) from game_ships_%_%s', game_id, player) into ships;
			if ships = 4 + 3 + 2 + 1 then
				select '	You READY' into additinal;
			else
				select '	You Preparing...' into additinal;
			end if;
		end if;
		if r.id = 4 then
			execute format('select count(*) from game_ships_%_%s', game_id, chr(asscii('a') + (asscii('b') - asscii(player)))) into ships;
			if ships = 4 + 3 + 2 + 1 then
				select 'Opponent READY' into additinal;
			else
				select 'Opponent Preparing...' into additinal;
			end if;
		end if;
		raise info '% % % % % % % % % % % %', format('%2s', r.id), r.A, r.B, r.C, r.D, r.E, r.F, r.G, r.H, r.I, r.J, additinal;
	end loop;
end;
$$

create or replace procedure game_place_cell(game_id text, player text, cell text, data text)
language plpgsql
as $$
declare
	col text;
	row text;
begin
	select substr(cell, 1, 1) into col;
	select substr(cell, 2, 1) into row;

	execute format('update game_field_%s_%s set %s =''%s'' where id = %s', game_id, player, col, data, row);
end
$$;

create or replace procedure game_place_react(game_id text, player text, from_cell text, to_cell text, data text)
language plpgsql
as $$
declare
	col_from text;
	col_to text;
	row_from text;
	row_to text;
	cell text;
begin
	select substr(from_cell, 1, 1) into col_from;
	select substr(from_cell, 2, 1) into row_from;
	select substr(to_cell, 1, 1) into col_to;
	select substr(to_cell, 2, 1) into row_to;

	for i in least(ascii(col_from), ascii(col_to))..greatest(ascii(col_from), ascii(col_to)) loop
		for j in least(row_from, row_to)..greatest(row_from, row_to) loop
			select format('%s%s', chr(i), j) into cell;
			call game_place_cell(game_id, player, call, data);
		end loop;
	end loop;
end
$$;