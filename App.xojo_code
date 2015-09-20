#tag Class
Protected Class App
Inherits Application
	#tag Event
		Sub Open()
		  App.AutoQuit = true
		  
		  dim dbFile as FolderItem = DatabaseFile
		  dim db as new SQLiteDatabase
		  db.DatabaseFile = dbFile
		  mParser = new Parser( db )
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h0
		Function Parser() As Parser
		  return mParser
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h21
		#tag Getter
			Get
			  dim f as FolderItem
			  
			  #if DebugBuild then
			    
			    f = GetFolderItem( "" )
			    f = f.Child( "Include In Resources" )
			    
			  #else
			    f = ResourcesFolder
			  #endif
			  
			  f = f.Child( "defaultdb.sqlite" )
			  return f
			  
			End Get
		#tag EndGetter
		Private DatabaseFile As FolderItem
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mParser As Parser
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  dim f as FolderItem = App.ExecutableFile.Parent.Parent
			  while f.Name <> "Contents"
			    f = f.Parent
			  wend
			  
			  f = f.Child( "Resources" )
			  return f
			End Get
		#tag EndGetter
		ResourcesFolder As FolderItem
	#tag EndComputedProperty


	#tag Constant, Name = kEditClear, Type = String, Dynamic = False, Default = \"&Delete", Scope = Public
		#Tag Instance, Platform = Windows, Language = Default, Definition  = \"&Delete"
		#Tag Instance, Platform = Linux, Language = Default, Definition  = \"&Delete"
	#tag EndConstant

	#tag Constant, Name = kFileQuit, Type = String, Dynamic = False, Default = \"&Quit", Scope = Public
		#Tag Instance, Platform = Windows, Language = Default, Definition  = \"E&xit"
	#tag EndConstant

	#tag Constant, Name = kFileQuitShortcut, Type = String, Dynamic = False, Default = \"", Scope = Public
		#Tag Instance, Platform = Mac OS, Language = Default, Definition  = \"Cmd+Q"
		#Tag Instance, Platform = Linux, Language = Default, Definition  = \"Ctrl+Q"
	#tag EndConstant


	#tag ViewBehavior
	#tag EndViewBehavior
End Class
#tag EndClass
