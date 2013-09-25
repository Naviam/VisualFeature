VERSION 5.00
Begin VB.Form Form1 
   BorderStyle     =   3  'Fixed Dialog
   Caption         =   "XML2RMS-TIMED"
   ClientHeight    =   840
   ClientLeft      =   45
   ClientTop       =   345
   ClientWidth     =   2655
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   840
   ScaleWidth      =   2655
   ShowInTaskbar   =   0   'False
   StartUpPosition =   3  'Windows Default
   Begin VB.CommandButton Act 
      Caption         =   "Start"
      BeginProperty Font 
         Name            =   "Arial"
         Size            =   12
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   375
      Left            =   0
      TabIndex        =   0
      Top             =   0
      Width           =   1095
   End
   Begin VB.Timer Timer 
      Left            =   0
      Top             =   240
   End
   Begin VB.Label Label0 
      Height          =   375
      Left            =   1680
      TabIndex        =   3
      Top             =   0
      Width           =   975
   End
   Begin VB.Label Label2 
      Height          =   375
      Left            =   1440
      TabIndex        =   2
      Top             =   480
      Width           =   1095
   End
   Begin VB.Label Label1 
      Height          =   375
      Left            =   120
      TabIndex        =   1
      Top             =   480
      Width           =   1095
   End
   Begin VB.Shape Shape1 
      BackStyle       =   1  'Opaque
      Height          =   375
      Left            =   1080
      Shape           =   3  'Circle
      Top             =   0
      Width           =   495
   End
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
Dim LocString As String
Dim ConnString As String
Dim ConnTimeout As String
Dim CommTimeout As String
Dim FilePath As String
Dim URL As String
Dim URLNote As String
Dim Msg As String
Dim Test As String
Dim InetUserName As String
Dim InetPassword As String
Dim FuncName As String
Dim MailProfName As String
Dim MailPassword As String
Dim Inter As String
Dim Auto As String


Dim CurConn As ADODB.Connection
Dim CurComm As ADODB.Command
Dim LocConn As ADODB.Connection
Dim RecSet As ADODB.Recordset

Dim WINET As WinHttpRequest



Dim Result
Dim Rab As String
Dim b() As Byte

Private Sub Form_Load()
    On Error GoTo ErrHandl
    
    Open App.Path & "\XML.ini" For Input As #1
    Line Input #1, Auto
    Line Input #1, Inter
    Line Input #1, LocString
    Line Input #1, ConnString
    Line Input #1, ConnTimeout
    Line Input #1, CommTimeout
    Line Input #1, FilePath
    Line Input #1, URL
    Line Input #1, URLNote
    'Line Input #1, INT_NUM
    Close
   
    Inter = IIf(IsNumeric(Inter), CInt(Inter), 10)
    Timer.Interval = 1000 * Inter
    Close #1
    'MsgBox ConnString & vbCrLf & MailServer & vbCrLf & FaxGateway & vbCrLf & FaxHostArea & vbCrLf & MailFrom, , "Holder Init"
    ToLog "Local Conn. String=" & LocString
    ToLog "Main Conn. String=" & ConnString
    ToLog "URL=" & URL
    ToLog "UrlNote=" & URLNote
    
    If Auto = "1" Then Act_Click
    'Caller.
    ErrHandl:

End Sub

Private Sub Act_Click()
    Select Case Act.Caption
    Case "Start"
        Act.Caption = "Stop"
        Timer.Enabled = True
    Case "Stop"
        Act.Caption = "Start"
        Timer.Enabled = False
    End Select
End Sub


Private Sub Timer_Timer()
    On Error GoTo lbErrHandl
    Timer.Enabled = False
    Dim RecID As String
    Dim NoteID As String
    Dim CheckID As String
    Dim ID As String
    Dim msgError As String


    If LocConn Is Nothing Then
        Set LocConn = New ADODB.Connection
        ToLog "LocConn - Created"
        LocConn.ConnectionString = LocString
        Shape1.BackColor = vbYellow
        Shape1.Refresh
        LocConn.Open
        ToLog "LocConn - OK"
    End If
    
    If CurConn Is Nothing Then
        Set CurConn = New ADODB.Connection
        ToLog "CurConn - Created"
        CurConn.ConnectionString = ConnString
        CurConn.CommandTimeout = ConnTimeout
        CurConn.CommandTimeout = CommTimeout
        Shape1.BackColor = vbBlue
        CurConn.Open
        Shape1.Refresh
        ToLog "CurConn - OK"
    End If
    
    If CurComm Is Nothing Then Set CurComm = New ADODB.Command
    
    Shape1.BackColor = vbYellow
    Shape1.Refresh

    Set RecSet = LocConn.Execute("select max(int(recID)) as maxID from Log ")
    RecID = RecSet.Fields!maxID.Value
    If CurConn Is Nothing Then
        Set CurConn = New ADODB.Connection
        ToLog "CurConn - Created"
        CurConn.ConnectionString = ConnString
        CurConn.CursorLocation = adUseClient 'adUseServer
        CurConn.ConnectionTimeout = ConnTimeout
        CurConn.CommandTimeout = CommTimeout
        Shape1.BackColor = vbBlue
        Shape1.Refresh
        CurConn.Open
        ToLog "CurConn - OK"
    End If
    If CurComm Is Nothing Then
        Set CurComm = New ADODB.Command
    End If

lbRec:
    
    CurComm.ActiveConnection = CurConn
    CurComm.CommandType = adCmdStoredProc
    CurComm.CommandText = "GenerateWoRecords2XML"
    CurComm.Parameters.Refresh
    
    CurComm.Parameters![@PIN] = "43939"
    CurComm.Parameters![@RecID] = RecID
    Shape1.BackColor = vbBlue
    Shape1.Refresh
    
    CurComm.Execute


    If Not IsNull(CurComm.Parameters![@RecID].Value) Then
        RecID = CurComm.Parameters![@RecID].Value
        'NoteID = IIf(IsNull(CurComm.Parameters![@PIN].Value), "null", CurComm.Parameters![@PIN].Value)
        NoteID = "null"     'nelson add it when switch the recid and noteid part.
        Msg = CurComm.Parameters![@XML].Value
        Shape1.BackColor = vbYellow
        Shape1.Refresh
        LocConn.Execute ("insert into Log(recID,noteID) values(" & RecID & "," & NoteID & ")")
        Set RecSet = LocConn.Execute("select max(ID)as IDEN from Log where recID='" & RecID & "'")
        ID = RecSet.Fields!IDEN.Value
        Rab = "ID=""" & ID & """"
        'ID%INT_NUM%
        Msg = Replace(Msg, "^ID^", Rab)
                                'Instatiate Inet object
        If WINET Is Nothing Then Set WINET = New WinHttpRequest
                            ' Open an HTTP connection.
        Shape1.BackColor = vbWhite
        Shape1.Refresh
        'Test = "Hello World"
        'Msg = Test
        ToLog Msg
        
        
        
        'MsgBox Msg
        WINET.Open "GET", URL & Msg, False
    
    
    
                            'Send the HTTP Request.
        WINET.Send
    
        ' GET all response text.
    
        Result = WINET.ResponseText
        msgError = ""
        msgError = Result
    
        'Result = IIf(Result Like "*>Success<*", "OK", "Error")
        Result = IIf(Result Like "*>OK<*", "OK", "Error")
        'If Result = "Error" Then
            ToLog msgError
        'End If
        Shape1.BackColor = vbYellow
        Shape1.Refresh
        Msg = Replace(Msg, "'", "''")
        LocConn.Execute ("update Log set Status='" & Result & "', Act='" & Msg & "' where ID=" & ID)
        'LocConn.Execute ("update Log set Status='" & Result & "',Act='Work Order' where ID=" & ID)
        Label0.Caption = ID
        Label1.Caption = RecID
        Label2.Caption = NoteID
        GoTo lbRec
    End If

    'Set RecSet = LocConn.Execute("select max(recID) as maxID from Log where isnull(Status) or Status='OK'")
    lbNote: '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>NOTES<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
    Shape1.BackColor = vbYellow '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>REQUESTS<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    Shape1.Refresh
    
    Set RecSet = LocConn.Execute("select max(int(noteID)) as nID from Log ")
    NoteID = RecSet.Fields!nID.Value
    CurComm.ActiveConnection = CurConn
    CurComm.CommandType = adCmdStoredProc
    CurComm.CommandText = "GenerateNoteRecordsNoProp2XML"
    CurComm.Parameters.Refresh
    CurComm.Parameters![@PIN] = "43939"          '"59769" replaced by FSN password
    CurComm.Parameters![@noteID] = NoteID
    Shape1.Refresh
    Shape1.BackColor = vbBlue
    CurComm.Execute
    
    
    If Not IsNull(CurComm.Parameters![@noteID].Value) Then 'NOTES
        NoteID = CurComm.Parameters![@noteID].Value
        'NoteID = CurComm.Parameters![@PIN].Value
        Msg = CurComm.Parameters![@XML].Value
        Shape1.BackColor = vbYellow
        Shape1.Refresh
        LocConn.Execute ("insert into Log(noteID) values('" & NoteID & "')")
        Set RecSet = LocConn.Execute("select max(ID)as IDEN from Log where noteID='" & NoteID & "'")
        ID = RecSet.Fields!IDEN.Value
        Rab = "ID=""" & ID & """"
        'ID%INT_NUM%
        Msg = Replace(Msg, "^ID^", Rab)
    
                            'Instatiate Inet object
        If WINET Is Nothing Then Set WINET = New WinHttpRequest
                            ' Open an HTTP connection.
        Shape1.BackColor = vbWhite
        Shape1.Refresh
        'MsgBox URL
        'MsgBox Msg
        WINET.Open "GET", URL & Msg, False
    
    
                            'Send the HTTP Request.
        ToLog Msg
        WINET.Send
    
        ' GET all response text.
        Result = WINET.ResponseText
        msgError = ""
        msgError = Result
        'Result = IIf(Result Like "*>Success<*", "OK", "Error")
        Result = IIf(Result Like "*>OK<*", "OK", "Error")
        'Result = IIf(Result Like "*>OK*OK*<*", "OK", "Error")
        'If Result = "Error" Then
            ToLog msgError
        'End If
        Shape1.BackColor = vbYellow
        Shape1.Refresh
        Msg = Replace(Msg, "'", "''")
        LocConn.Execute ("update Log set Status='" & Result & "', Act='" & Msg & "' where ID=" & ID)
        'LocConn.Execute ("update Log set Status='" & Result & "',Act = 'Note' where ID=" & ID)
        GoTo lbNote
    End If

    'comment OUT IVR
    lbGapCheck: '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Check in/out<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'
    
    Shape1.BackColor = vbYellow '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>REQUESTS<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    Shape1.Refresh
    '
    Set RecSet = LocConn.Execute("select max(int(checklogID)) as cID from Log ")
    CheckID = RecSet.Fields!cID.Value
    CurComm.ActiveConnection = CurConn
    CurComm.CommandType = adCmdStoredProc
    CurComm.CommandText = "GenerateIVRRecords2XML"
    CurComm.Parameters.Refresh
    CurComm.Parameters![@PIN] = "43939"
    CurComm.Parameters![@ivrlogID] = CheckID
    Shape1.Refresh
    Shape1.BackColor = vbBlue
    CurComm.Execute
    '
    If Not IsNull(CurComm.Parameters![@ivrlogID].Value) Then 'NOTES
        CheckID = CurComm.Parameters![@ivrlogID].Value
        Msg = CurComm.Parameters![@XML].Value
        Shape1.BackColor = vbYellow
        Shape1.Refresh
        LocConn.Execute ("insert into Log(checklogid) values('" & CheckID & "')")
        Set RecSet = LocConn.Execute("select max(ID)as IDEN from Log where checklogID='" & CheckID & "'")
        ID = RecSet.Fields!IDEN.Value
        Rab = "ID=""" & ID & """"
        'ID%INT_NUM%
        Msg = Replace(Msg, "^ID^", Rab)
    
                            'Instatiate Inet object
        If WINET Is Nothing Then Set WINET = New WinHttpRequest
                            ' Open an HTTP connection.
        Shape1.BackColor = vbWhite
        Shape1.Refresh
        'MsgBox URL
        'MsgBox Msg
        WINET.Open "GET", URL & Msg, False
    
        ToLog Msg
        WINET.Send
    '
        ' GET all response text.
        Result = WINET.ResponseText
        msgError = ""
        msgError = Result
        Result = IIf(Result Like "*>OK<*", "OK", "Error")
       'Result = IIf(Result Like "*>Success<*", "OK", "Error")
        'If Result = "Error" Then
            ToLog msgError
        'End If
        Shape1.BackColor = vbYellow
        Shape1.Refresh
        Msg = Replace(Msg, "'", "''")
        LocConn.Execute ("update Log set Status='" & Result & "', Act='" & Msg & "' where ID=" & ID)
        'LocConn.Execute ("update Log set Status='" & Result & "',Act = 'Note' where ID=" & ID)
        GoTo lbGapCheck
    End If
    
    
    Shape1.BackColor = vbGreen
    Shape1.Refresh
    Timer.Enabled = True
    
    'Exit and let the timer restart
    End
    
    
    Exit Sub
    lbErrHandl:
    ToLog Err.Description & " (" & Err.Number & ")"
    Shape1.BackColor = vbRed
    Shape1.Refresh
    Timer.Enabled = True
    
    'Set MAPIS = New MAPI.Session
    'MAPIS.Logon MailProfName, MailPassword
End Sub

Private Sub ToLog(pMsg As String)
    Dim sMsg As String
    Dim lNewFile As String
    Dim lLogFile As String
    Dim Handl As Integer
    On Error GoTo Err_Handl
    sMsg = pMsg
    If Dir(App.Path & "\Log", vbDirectory) = "" Then MkDir (App.Path & "\Log")
    lLogFile = App.Path & "\Log\" & "XMLlog.csv"
    If (Dir(lLogFile) <> "") Then
        If FileLen(lLogFile) > 500000 Then
            If Dir(App.Path & "\Log\Archive", vbDirectory) = "" Then MkDir (App.Path & "\Log\Archive")
            lNewFile = App.Path & "\Log\Archive\XML" & Format$(Now, "mmddyyyyHhNnSs") & ".csv"
            Name lLogFile As lNewFile
        End If
    Else
        lNewFile = "*" 'For header
    End If
    Handl = FreeFile()
    Open lLogFile For Append As #Handl
    If lNewFile <> "" Then Print #Handl, "Time,Message"
    sMsg = """" & Format(Now(), "mm/dd/yy hh:nn:ss") & """,""" & sMsg & """"
    Print #Handl, sMsg                       'Write to the log file
    Close #Handl
Exit Sub
Err_Handl:
    'MsgBox "Error is: " & Err.Description, vbCritical, "WriteToLog Error"
    Close #Handl
End Sub



