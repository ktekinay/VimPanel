#tag Class
Protected Class Parser
	#tag Method, Flags = &h0
		Sub AddCharacter(char As String)
		  Stack = Stack + EncodeChar( char )
		  SplitStack
		  
		  mMessage = Stack
		  
		  if CurrentSequence = "" then
		    //
		    // Only the repetitions were added, so wait
		    //
		    return
		  end if
		  
		  dim script as string
		  if SequenceRecordIDs.Ubound = 0 then // Found one after last search
		    
		    script = FetchScript( SequenceRecordIDs( 0 ) )
		    
		  else
		    
		    dim sql as string = "SELECT * FROM sequences WHERE SUBSTR( sequence, 1, " + str( CurrentSequence.Len ) + " ) = ?"
		    dim ps as PreparedSQLStatement = DB.Prepare( sql )
		    ps.BindType( 0, SQLitePreparedStatement.SQLITE_TEXT )
		    
		    dim rs as RecordSet = ps.SQLSelect( CurrentSequence )
		    if rs is nil or rs.RecordCount = 0 then
		      Reset
		      mMessage = kMessageInvalidSequence
		      
		    elseif rs.RecordCount > 1 or rs.Field( "takes_param" ).BooleanValue then
		      //
		      // More then one match or waiting for a param
		      //
		      mMessage = ""
		      redim SequenceRecordIDs( -1 )
		      while not rs.EOF
		        SequenceRecordIDs.Append rs.Field( "id" ).IntegerValue
		        rs.MoveNext
		      wend
		      
		    else
		      //
		      // We found one match and it doesn't need a param, so let's go
		      //
		      script = FetchScript( rs.Field( "script_id" ).IntegerValue )
		      
		    end if
		    
		  end if
		  
		  if script <> "" then
		    dim msg as string
		    for i as integer = 1 to Repetitions
		      msg = ExecuteScript( script, CurrentSequence )
		    next
		    
		    Reset
		    mMessage = msg
		  end if
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(db As Database)
		  if not db.Connect then
		    dim err as new RuntimeException
		    err.Message = "Could not connect to database."
		    raise err
		  end if
		  
		  mDB = db
		  Reset
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function DB() As Database
		  return mDB
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function EncodeChar(char As String) As String
		  dim result as string = char
		  
		  select case char.Asc
		  case 3
		    result = "ENT"
		    
		  case 8
		    result = "DEL"
		    
		  case 9
		    result = "TAB"
		    
		  case 10
		    result = "LF"
		    
		  case 13
		    result = "RET"
		    
		  case is <= 26
		    result = "CTRL+" + Chr( char.Asc + 64 )
		    
		  case 27
		    result = "ESC"
		    
		  case 28
		    result = "LEFT"
		    
		  case 29
		    result = "RIGHT"
		    
		  case 30
		    result = "UP"
		    
		  case 31
		    result = "DOWN"
		    
		  case &h7F
		    result = "FDEL"
		    
		  end select
		  
		  if result <> char then
		    result = "•" + result + "•"
		  end if
		  
		  return result
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ExecuteScript(script As String, params As String) As String
		  dim sh as new Shell
		  dim cmd as string = "/usr/bin/osascript -e " + ShellQuote( script ) + " " + ShellQuote( params )
		  sh.Execute cmd
		  return sh.Result.Trim.DefineEncoding( Encodings.UTF8 )
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function FetchScript(id As Integer) As String
		  dim sql as string = "SELECT id, script FROM scripts WHERE id = ?"
		  dim ps as PreparedSQLStatement = DB.Prepare( sql )
		  ps.BindType( 0, SQLitePreparedStatement.SQLITE_TEXT )
		  
		  dim rs as RecordSet = ps.SQLSelect( id )
		  return rs.Field( "script" ).StringValue.DefineEncoding( Encodings.UTF8 )
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Message() As String
		  return mMessage
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Reset()
		  redim SequenceRecordIDs( -1 )
		  CurrentSequence = ""
		  Stack = ""
		  Repetitions = 1
		  mMessage = ""
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function ShellQuote(s As String) As String
		  s = ReplaceLineEndings( s, &u0A )
		  s = s.ReplaceAll( "'", "'\''" )
		  s = "'" + s + "'"
		  return s
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub SplitStack()
		  static rx as RegEx
		  if rx is nil then
		    rx = new RegEx
		    rx.SearchPattern = "^([1-9]\d*)?(.*)"
		  end if
		  
		  if Stack = "" then
		    
		    Repetitions = 1
		    CurrentSequence = ""
		    
		  else
		    
		    dim match as RegExMatch = rx.Search( Stack )
		    if match.SubExpressionString( 1 ) <> "" then
		      Repetitions = val( match.SubExpressionString( 1 ) )
		    else
		      Repetitions = 1
		    end if
		    if match.SubExpressionCount = 3 then
		      CurrentSequence = match.SubExpressionString( 2 )
		    else
		      CurrentSequence = ""
		    end if
		    
		  end if
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h21
		Private CurrentSequence As String
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mMessage <> kMessageInvalidSequence
			End Get
		#tag EndGetter
		IsValid As Boolean
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mDB As Database
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mMessage As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private Repetitions As Integer = 1
	#tag EndProperty

	#tag Property, Flags = &h21
		Private SequenceRecordIDs() As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private Stack As String
	#tag EndProperty


	#tag Constant, Name = kMessageInvalidSequence, Type = String, Dynamic = False, Default = \"invalid sequence", Scope = Private
	#tag EndConstant


	#tag ViewBehavior
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="IsValid"
			Group="Behavior"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
