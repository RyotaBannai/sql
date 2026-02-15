/* Query executed on April 16, 2020 at 4:54:48 PM */
select 
	id_excluded as id,
	(select group_concat(id) from my_table where id != id_excluded) as other_ids 
	from (select id as id_excluded from my_table) tab_dummy; -- Every derived table must have its own alias