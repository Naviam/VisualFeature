/***************************************************************************************
*
* &Name:     GenerateNoteRecords2XML
* &Desc:      
* &Modified: V.Perepechko / Elifelab
* &Date:     10/12/2012
* &Modified: afetisov / ServiceChannel
* &Date:     10/19/2012
*
***************************************************************************************/
CREATE PROCEDURE [dbo].[GenerateNoteRecords2XML](@PIN int, @noteID int output, @XML nvarchar(4000) output)
as

set nocount on

if @PIN is null or @noteID is null return -1

declare
	@proID int,
	@subID int,
	@recID int,
	@noteNum int,
	@noteText nvarchar(2000),
	@noteDate datetime,
	@Date_Diff int,
	@noteBy varchar(100),
	@noteSched datetime,
	@noteTo varchar(200),
	@noteReason varchar(100),

	@wo_# varchar(20),
	@prop_id varchar(30),
	@prop_date datetime,
	@prop_reqby varchar(40),
	@prop_des varchar(2000),
	@prop_incur varchar(20),	
	@prop_labor varchar(20),		
	@prop_material varchar(20),
	@prop_freight varchar(20),	
	@prop_other varchar(20),	
	@prop_otherdesc varchar(100),
	@prop_tax varchar(20),
	@prop_total varchar(20),

	@totalprop money,
	@nte money,
	@nextNoteID int = null,
	@FullStatus varchar(100),
	@currentStatus varchar(100)

	


select @proID = pro_id from scuser with(nolock) where id = @PIN

if @proID is null
begin
	set @noteID = null
	return -1
end

select top 1 
	@nextNoteID = ws.woNoteID,
	@recID = ws.trackingNumber
from workorder_notes_staging ws with(nolock) 
where ws.providerID = @proID
    and ws.woNoteID > @noteID
    and ws.isProcessed = 0
order by ws.woNoteID asc

set @noteID = @nextNoteID

if @noteID is null 	return -1


select top 1
	@noteNum = NoteNum,
	@noteText = left(Note,2000),
	@noteDate = Date_Created,
	@noteBy = CreatedBy,
	@noteSched = Scheduled_Date,
	@noteTo = MailedTo,
	@noteReason = ReschedReason,
	@wo_# = wo_#
from tbWO_notes with(nolock)
where recid = @recID and id = @noteID
  
set @noteText = replace(replace(replace(replace(@noteText,'>','&gt;'),'<','&lt;'),'"','&quot;'),'''','&apos;')

select top 1 
	@Date_Diff = abs(datediff(s,isnull(dateUpdated,'01/01/2005'), @noteDate)),
	@nte = nte 
from screc_NTE with(nolock)
where recID = @recID

select top 1 
	@prop_id =id,	
	@prop_date = date,
	@prop_reqby = requestedby,
	@prop_des = ltrim(rtrim(left([description],2000))),
	@prop_incur = convert(varchar(20),inctotal),
	@prop_labor =  convert(varchar(20),labor),
	@prop_material = convert(varchar(20),materials),
	@prop_freight =  convert(varchar(20),freight),
	@prop_other =  convert(varchar(20),other),
	@prop_otherdesc = otherdescription,
	@prop_tax =  convert(varchar(20),tax),
	@totalprop =  amount
from proposals with (nolock)
where provider_id = @proID 
	and [status] = 'APPROVED'
	and wo_# = @wo_#
order by [Date] desc

set @prop_des = replace(replace(replace(replace(@prop_des,'>','&gt;'),'<','&lt;'),'"','&quot;'),'''','&apos;')

set @prop_otherdesc = ltrim(rtrim(replace(replace(replace(replace(@prop_otherdesc,'>','&gt;'),'<','&lt;'),'"','&quot;'),'''','&apos;')))


select 
	@currentStatus = current_status, 
	@FullStatus = ltrim(rtrim(isnull(StatusExt,''))),
	@subID = sub_id
from screc with(nolock) 
where recid = @recid

declare @status_map table (
	oldStatus varchar(100),
	newStatus varchar(100)
)

insert @status_map (oldStatus, newStatus)
values 
('',@currentStatus),
('TRADE DECLINED', 'TRADE_DECLINED'),
('ETA DECLINED', 'TIME_DECLINED'),
('DISPATCH CONFIRMED', 'DISPATCH_CONFIRMED'),
('TRADE DECLINED', 'TRADE_DECLINED'),  
('ETA DECLINED', 'TIME_DECLINED'), 
('LOCATION DECLINED', 'LOCATION_DECLINED'),
('PARTS ON ORDER', 'PARTS_ON_ORDER'),
('WAITING FOR QUOTE', 'WAITING_FOR_QUOTE'),
('WAITING FOR APPROVAL', 'WAITING_FOR_APPROVAL'), 
('PROPOSAL APPROVED', 'PROPOSAL_APPROVED'), 
('PENDING CONFIRMATION', 'COMPLETED_PENDING'),
('CONFIRMED', 'COMPLETED_CONFIRMED'), 
('NO CHARGE', 'COMPLETED_NO_CHARGE'),
('ON SITE', 'ON_SITE')	

set @FullStatus = isnull((select newStatus from @status_map where oldStatus = @FullStatus),@FullStatus)


declare
	@SCHDDATE datetime,
	@COMPLTIME datetime,
	@callDate datetime,
	@CALLER varchar(100),
	@CATEGORY varchar(100),
	@LOC varchar(100),
	@TRADE varchar(100),
	@WO_NUM varchar(100),
	@PO_NUM varchar(100),
	@PRIORITY varchar(100),
	@PROBLEM nvarchar(4000),
	@RECALL varchar(100),
	@RECALL_TR_# varchar(100),
	@createdBy varchar(100),
	@INT_NUM varchar(20)

	
	
select
	@callDate = r.call_date,
	@WO_NUM = r.WO_#,
	@PO_NUM = r.PO_#,
	@createdBy = r.CreatedBy,
	@CALLER = r.[caller],
	@CATEGORY = r.Discretionary,
	@LOC = l.store_id,
	@TRADE = c.[type],
	@PRIORITY = r.PrioritySub,
	@SCHDDATE = r.scheduled_date,
	@COMPLTIME = r.Compl_Date,
	@RECALL_TR_# = rc.OriginalTracking_#,
	@PROBLEM = r.problem
	
from screc r with(nolock)
left join screc_recall rc with(nolock) on rc.recID = r.recID
inner join sccon c with(nolock) on r.con_id = c.id
inner join scloc l with(nolock) on r.loc_id = l.id 
where r.recID = @recID

set @prop_total = convert(varchar(20),@totalprop)

set @INT_NUM = case when @prop_id is not null and @totalprop = @nte then 'WITH PROP' else 'NO PROP' end

set  @XML = '<?xml version="1.0"?><DATA2SC PIN="'+cast(@PIN as varchar(10))+'" ^ID^ '
	+'INT_NUM="' + @INT_NUM + '"><CALL'
	+isnull(' DATETIME="'+replace(convert(varchar(20),@callDate,120),'-','/')+'"','')
	+isnull(' TR_NUM="'+cast(@recID as varchar(50))+'"','')
	+isnull(' WO_NUM="'+cast(ltrim(rtrim(@WO_NUM)) as varchar(50))+'"','')
	+isnull(' PO_NUM="'+cast(ltrim(rtrim(@PO_NUM)) as varchar(50))+'"','')
	+ case when @prop_id is not null and @totalprop = @nte then isnull(' PROP_NUM="' + @prop_id + '"','') else '' end
	+isnull(' OPERATOR="'+ltrim(rtrim(@createdBy))+'"','')
	+isnull(' CALLER="'+ltrim(rtrim(@CALLER))+'"','')
	+isnull(' CATEGORY="'+ltrim(rtrim(@CATEGORY))+'"','')
	+isnull(' SUB="' + convert(varchar(20),@subID)+ '"','')	
	+isnull(' LOC="'+ltrim(rtrim(@LOC))+'"','')
	+isnull(' TRADE="'+ltrim(rtrim(@TRADE))+'"','')
	+isnull(' STATUS="'+ltrim(rtrim(@FullStatus))+'"','')
	+isnull(' PRIORITY="' + @PRIORITY + '"','')
	+isnull(' NTE="'+isnull(cast(@nte as varchar(50)),'')+'"','')
	+isnull(' SCHED_DATETIME="'+replace(convert(varchar(20),@SCHDDATE,120),'-','/')+'"','')
	+isnull(' COMPL_DATETIME="'+replace(convert(varchar(20),@COMPLTIME,120),'-','/')+'"','')
	+isnull(' RECALL="' + case when @noteText like '%recall%' then 'Y' end +'"','')
	+isnull(' RECALL_TR_NUM="'+cast(@RECALL_TR_# as varchar(50))+'"','')
	+'>'+isnull('<PROBLEM>'+replace(replace(replace(replace(ltrim(rtrim(@PROBLEM)),'>','&gt;'),'<','&lt;'),'"','&quot;'),'''','&apos;') + '</PROBLEM>','')
		+'<ATTR NAME="NOTE" LINE="'+cast(@noteNum as varchar(10))+'"'+
		+isnull(' DATETIME="'+replace(convert(varchar(20),@NOTEDATE,120),'-','/')+'"','')+
		+isnull(' CREATED_BY="'+ltrim(rtrim(@noteBy))+'"','')+
		+isnull(' NEW_SCHED_DATETIME="'+replace(convert(varchar(20),@noteSched,120),'-','/')+'"','')
		+isnull(' RESCHED_REASON="'+ltrim(rtrim(@noteReason))+'"','')
		+isnull(' SENT_TO="'++ltrim(rtrim(@noteTo))+'"','') 
		+'>'+replace(replace(@noteText,'
		',' '),'  ','')+'</ATTR>'
		
		+ case when @prop_id is not null and @totalprop = @nte then 
			isnull('<PROP ID ="'+@prop_id+'"','')
			+isnull(' DATE="'+replace(convert(varchar(20),@prop_date,120),'-','/')+'"','')
			+isnull(' REQ_BY="'+@prop_reqby+'"','')
			+isnull(' TEXT="'+@prop_des+'"','')
			+isnull(' INCUR="$'+@prop_incur+'"','')
			+isnull(' LABOR="$'+@prop_labor+'"','')
			+isnull(' MATERIAL="$'+@prop_material+'"','')
			+isnull(' FREIGHT="$'+@prop_freight+'"','')
			+isnull(' OTHER="$'+@prop_other+'"','')
			+isnull(' OTHER_DESC="'+@prop_otherdesc+'"','')
			+isnull(' TAX="$'+@prop_tax+'"','')
			+isnull(' TOTAL="$'+@prop_total+'"','')
		+'></PROP>' else '' end
	+'</CALL></DATA2SC>' 

set @XML = replace(replace(replace(replace(replace(@XML,'?xml version="1.0"?','^xml version="1.0"^'),'&',' and '),'?',' '),'  ',' '),'^xml version="1.0"^','?xml version="1.0"?')

update workorder_notes_staging 
set isProcessed = 1
where providerID  = @proID and woNoteID = @noteID

