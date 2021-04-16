# Iterates over a set and deletes

declare @error varchar(max)='STRING'
declare @many int
declare @packet int=200

select @cmany=count(*) from #TABLE# with(nolock) where message=@error
print @error
print @many

set nocount on;

while (@many > 0)
begin
	select @many=count(*) from #TABLE# with(nolock) where message=@error

	delete top(@packet) from #TABLE# where message=@error

	print @cuantos

end