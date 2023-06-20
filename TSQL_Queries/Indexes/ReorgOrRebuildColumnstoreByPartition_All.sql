/*
	============================================
	   Rebuild Columnstore Index By partition
	============================================
	This query will loop through all partitions in a table and rebuild
	the columnstore index per partition. Perfoming rebuilds this way require
	a smaller memory grant 
	
	Choose whether you want to perform a reorganize (online) or REBUILD (offline) by 
	commenting and uncommenting the proper command. 
	
*/
DECLARE @schemaName VARCHAR(50) = 'dbo' 
DECLARE @tableName VARCHAR(100)= 'FactInternetSales_partitioned'
DECLARE @counter INT 
DECLARE @partitionCount INT 


SET @counter=1
SET @partitionCount=(
			SELECT 
				max(p.partition_number) AS 'Num_Partitions'
			FROM sys.partitions p
			JOIN sys.tables t
				ON P.object_id = t.object_id
			JOIN sys.schemas s
				ON t.[schema_id] = s.[schema_id]
			WHERE s.name = @schemaName
			AND t.name = @tableName
			group by s.[name],t.[name]
			)

WHILE ( @counter <= @partitionCount)
BEGIN
	DECLARE @s NVARCHAR(4000) = N''

	--Choose whether or not you want to do a rebuild or reorganize by uncommenting the proper command. Default is reorganize.
	--SET @s = ('ALTER INDEX ALL ON ' + @schemaName + '.' + @tableName + ' REBUILD PARTITION = ' + CAST(@counter AS varchar(10))) --rebuild command (offline operation)
	SET @s = ('ALTER INDEX ALL ON ' + @schemaName + '.' + @tableName + ' REORGANIZE PARTITION = ' + CAST(@counter AS varchar(10)) + ' WITH (COMPRESS_ALL_ROW_GROUPS = ON)') --REORGANIZE command (online operation)
	PRINT @s

	EXEC sp_executesql @s

    SET @counter  = @counter  + 1
END