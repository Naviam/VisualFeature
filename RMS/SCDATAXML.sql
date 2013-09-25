declare @XMLout varchar(8000)
declare @PIN varchar(100)
declare @ID int
declare @INT_NUM varchar(100)
declare @DATETIME datetime
declare @OPERATOR varchar(100)
declare @CALLER varchar(100)
declare @CATEGORY varchar(100)
declare @SUB varchar(100)
declare @LOC varchar(100)
declare @TRADE varchar(100)
declare @PRO varchar(100)
declare @TR_NUM varchar(100)
declare @PO_NUM varchar(100)
declare @STATUS varchar(100)
declare @PRIORITY varchar(100)
declare @NTE varchar(100)
declare @PROBLEM varchar(7000)

declare @recID int
declare @subID int
declare @locID int
declare @conID int
declare @proID int

set @recID=11686682

set @PIN='59769'
set @ID=1
set @INT_NUM='IF-OE-06'
--set @SUB='GAP'
--set @PRO='YORK INTERNATIONAL CORP.'

select @TR_NUM=recID,@DATETIME=call_date,@OPERATOR=createdBy,@CALLER=caller,@CATEGORY=discretionary,
	@subID=sub_id,@locID=loc_id,@conID=con_id,@proID=provider_id,@PO_NUM=PO_#,@STATUS=current_status,
	@PRIORITY=prioritySub,@PROBLEM=problem
	from screc where recID=@recID
	
select @SUB=sub_short_name, @PRO=pro_short_name from scspr where sub_id=@subID and pro_id=@proID
select @LOC=store_id from scloc where id=@locID
select @TRADE=type from sccon where id=@conID
select @NTE=convert(varchar(20),NTE) from screc_NTE where recID=@recID

select @XMLout='<?xml version=''1.0''?><DATA2SC PIN="'+@PIN+'" ID="'+cast(@ID as varchar(10))+
		'" INT_NUM="'+@INT_NUM+'"><CALL '
		+isnull('DATETIME="'+cast(@DATETIME as varchar(20))+'" ','')
		+isnull('OPERATOR="'+@OPERATOR+'" ','')
		+isnull('CALLER="'+@CALLER+'" ','')
		+isnull('CATEGORY="'+@CATEGORY+'" ','')
		+isnull('SUB="'+@SUB+'" ','')
		+isnull('LOC="'+@SUB,'')
		+isnull('TRADE="'+@SUB+'" ','')
		+isnull('PRO="'+@PRO+'" ','')
		+isnull('TR_NUM="'+@TR_NUM+'" ','')
		+isnull('PO_NUM="'+@PO_NUM+'" ','')
		+isnull('STATUS="'+@STATUS+'" ','')
		+isnull('PRIORITY="'+@PRIORITY+'" ','')
		+isnull('NTE="$'+@NTE+'" ','')
		+'>'
		+isnull('<PROBLEM>'+@PROBLEM+'</PROBLEM>','')
	+'</CALL></DATA2SC>'
print @XMLout