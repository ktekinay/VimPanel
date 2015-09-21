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
		      redim SequenceRecordIDs( -1 )
		      while not rs.EOF
		        SequenceRecordIDs.Append rs.Field( "id" ).IntegerValue
		        rs.MoveNext
		      wend
		      
		    else
		      //
		      // We found one match and it doesn't need a param, so let's go
		      //
		      script = FetchScript( rs.Field( "id" ).IntegerValue )
		    end if
		    
		  end if
		  
		  if script <> "" then
		    dim msg as string
		    msg = ExecuteScript( script, useSequence, Repetitions )
		    
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
		  dim r as string
		  for i as integer = 0 to &hFF
		    if Keyboard.AsyncKeyDown( i ) then
		      r = Keyboard.KeyName( i )
		      if r = "Shift" or r = "Control" or r = "Option" then
		        continue for i
		      end if
		      
		      dim isSame as boolean = r = char
		      if isSame or ( char.Asc > 31 and r.LenB = 1 ) then
		        r = char // Will preserve the actual key
		        
		        //
		        // If the shift key is down but that won't make a difference to the actual character, record that the shift key is down
		        //
		        if Keyboard.ShiftKey and isSame and ( Keyboard.ControlKey or StrComp( char.Lowercase, char.Uppercase, 0 ) = 0 ) then
		          r = kShiftPrefix + r
		        end if
		        
		      else
		        r = r.Uppercase
		        if Keyboard.ShiftKey then
		          r = kShiftPrefix + r
		        end if
		      end if
		      
		      if Keyboard.ControlKey then
		        r = kControlPrefix + r
		      end if
		      exit for i
		    end if
		  next
		  
		  if r <> char then
		    r = "•" + r + "•"
		  end if
		  
		  return r
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ExecuteScript(script As String, seq As String, reps As Integer) As String
		  if reps < 1 then
		    reps = 1
		  end if
		  
		  dim sh as new Shell
		  dim cmd as string = "/usr/bin/osascript -e " + ShellQuote( script ) + " " + ShellQuote( seq ) + " " + str( reps )
		  sh.Execute cmd
		  return sh.Result.Trim.DefineEncoding( Encodings.UTF8 )
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function FetchScript(id As Integer) As String
		  dim sql as string = "SELECT script FROM sequences LEFT JOIN scripts ON sequences.script_id = scripts.id WHERE sequences.id = ?"
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


	#tag Constant, Name = kControlPrefix, Type = String, Dynamic = False, Default = \"CTRL+", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kMessageInvalidSequence, Type = String, Dynamic = False, Default = \"invalid sequence", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kShiftPrefix, Type = String, Dynamic = False, Default = \"SHIFT+", Scope = Private
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
