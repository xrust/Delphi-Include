unit uCommon64;
{//----------------------------------------------------------------------------α
    Set Of Common Functions for Delphi(12) Windows Platform 32 and 64 bits
}//----------------------------------------------------------------------------+
interface
//-----------------------------------------------------------------------------+
uses
Winapi.Windows,
Winapi.Messages,
Winapi.WinSock,
//---
System.SysUtils,
System.Types,
System.Classes,
System.Variants,
//---
VCL.Forms,
VCL.StdCtrls,
VCL.ExtCtrls,
VCL.Mask
;
//-----------------------------------------------------------------------------+
const INT_MAX = 2147483647;
const INT_MIN = -2147483647;
const UINT_MAX = 4294967295;
const INT64_MAX = 9223372036854775807;
const INT64_MIN = -9223372036854775807;
//-----------------------------------------------------------------------------+
type
TStr16 = string[16];
TStr32 = string[32];
TStr64 = string[64];
TStr128= string[128];
//---
TDByteArr = TArray<Byte>;
TDWordArr = TArray<Word>;
TDIntArr = TArray<Integer>;
TDInt64Arr = TArray<Int64>;
TDDoubleArr = TArray<Double>;
TDSsArr = TArray<ShortString>;
TDStringArr = TArray<String>;
//-----------------------------------------------------------------------------+
type TTypeOfVars = (tvString,tvUint,tvInt,tvDouble,tvIpAddr,tvDate,tvTime,tvDateTime);
//-----------------------------------------------------------------------------+
procedure CheckKeyPress(TypeVar:TTypeOfVars; WinComp:TComponent; var Key: Char);
//-----------------------------------------------------------------------------+
function  HaveDir(const fn:string; const create:boolean=true):boolean;
function  GetLocalIP: String;
function  IsRightAddr(InConnectAddr:string;AllowedIPs:string='*'):Boolean;
function  FileVersion(AFileName: string): string;
function  VarToString(Value: Variant):String;overload;
function  VarToStringF(Value: Variant; Digits:Byte=8):String;overload
procedure ArrSort(var Data:array of Word; SortByDecrement:Boolean=False);overload;
procedure ArrSort(var Data:array of Integer; sortByDecrement:Boolean=False);overload;
procedure ArrSort(var Data:array of Int64; sortByDecrement:Boolean=False);overload;
procedure ArrSort(var Data:array of Double; sortByDecrement:Boolean=False);overload;
procedure ArrSort(var Data:array of ShortString; sortByDecrement:Boolean=False);overload;
procedure ArrSort(var Data:array of AnsiString; sortByDecrement:Boolean=False);overload;
//-----------------------------------------------------------------------------+
implementation
//-----------------------------------------------------------------------------+
procedure CheckKeyPress(TypeVar:TTypeOfVars; WinComp:TComponent; var Key: Char);
var text:string;
begin
    //---
    if( WinComp.ClassType = TEdit )then text:=TEdit(WinComp).Text;
    if( WinComp.ClassType = TMaskEdit )then text:=TMaskEdit(WinComp).Text;
    if( WinComp.ClassType = TLabeledEdit )then text:=TEdit(TLabeledEdit).Text;
    if( WinComp.ClassType = TComboBox )then text:=TEdit(TComboBox).Text;
    //---
    case( TypeVar )of
        tvUint : begin
            case Key of
                '0'..'9':;
                #8:;
            else
                key := #0;
            end;
        end;
        tvInt : begin
            case Key of
                '0'..'9':;
                '-':if( Length(Text)>0 )then Key:=#0;
                #8:;
            else
                key := #0;
            end;
        end;
        tvDouble :begin
            case Key of
            '0'..'9':;
            '-':if( Length(Text)>0 )then Key:=#0;
            '.':begin
                    if( Length(Text)<1 )then Key:=#0;
                    if( Text = '-' )and( Length(Text) = 1 )then Key:=#0;
                    if( Pos('.',Text) > 0 )then Key:=#0;
                end;
            #8:;
            else
                key := #0;
            end;
        end;
        tvIpAddr :begin
            case key of
                '0'..'9': ; // цифры
                #8: ; // забой
                '.':;
                '*':
            else
                key := #0;
            end;
        end;
    end;
end;
//-----------------------------------------------------------------------------+
function VarToString(Value: Variant):String;
begin
    Result:='';
    FormatSettings.DecimalSeparator:='.';
    try
        case TVarData(Value).VType of
            varByte,
            varShortInt,
            varSmallInt,
            varInteger,
            varWord,
            varLongWord : Result := IntToStr(Value);
            varInt64    : Result := IntToStr(Value);
            varSingle,
            varDouble,
            varCurrency : Result := FloatToStr(Value);
            varDate     : Result := FormatDateTime('yyyy.mm.dd hh:nn:ss', Value);
            varBoolean  : if Value then Result := 'True' else Result := 'False';
            varString,
            varUString,
            varUStrArg  : Result := Value;
            else          Result := 'varUnknown! ';
        end;
    except
        on E : Exception do E:=nil;
    end;
end;
//-----------------------------------------------------------------------------+
function VarToStringF(Value: Variant; Digits:Byte=8):String;
begin
    Result:='';
    FormatSettings.DecimalSeparator:='.';
    try
        case TVarData(Value).VType of
            varByte,
            varShortInt,
            varSmallInt,
            varInteger,
            varWord,
            varLongWord : Result := IntToStr(Value);
            varInt64    : Result := IntToStr(Value);
            varSingle,
            varDouble,
            varCurrency : Result := FloatToStrF(Value,ffFixed,20,Digits);
            varDate     : Result := FormatDateTime('yyyy.mm.dd hh:nn:ss', Value);
            varBoolean  : if Value then Result := 'True' else Result := 'False';
            varString,
            varUString,
            varUStrArg  : Result := Value;
            else          Result := '';
        end;
    except
        on E : Exception do E:=nil;
    end;
end;
//-----------------------------------------------------------------------------+
function HaveDir(const fn:string; const create:boolean=true):boolean;
var path:string;
begin
   path:=Copy(fn,1,Lastdelimiter('\',fn));
   result:=DirectoryExists(path);
   if not result then begin
      if(create)then begin
         Result:=ForceDirectories(path);
      end;
   end;
end;
//-----------------------------------------------------------------------------+
function GetLocalIP: String;
const WSVer = $101;
var
wsaData: TWSAData;
P: PHostEnt;
Buf: array [0..127] of AnsiChar;
begin
    Result := '';
    if WSAStartup(WSVer, wsaData) = 0 then begin
        if GetHostName(@Buf[0], 128) = 0 then begin
            P := GetHostByName(@Buf[0]);
            if P <> nil then Result := string(inet_ntoa(PInAddr(p^.h_addr_list^)^));
        end;
        WSACleanup;
    end;
end;
//-----------------------------------------------------------------------------+
function IsRightAddr(InConnectAddr:string;AllowedIPs:string='*'):Boolean;
var
i,ii:Integer;
list:TStringList;
addr:string;
ignore,found:Boolean;
begin
    Result:=True;
    if( AllowedIPs = '' )or(AllowedIPs = '*')then Exit;                                             // разрешаем всe
    //---
    InConnectAddr:=StringReplace(InConnectAddr,'.','',[rfReplaceAll, rfIgnoreCase]);                // убрали разделители во входящем айпи
    AllowedIPs:=StringReplace(AllowedIPs,' ','',[rfReplaceAll, rfIgnoreCase]);                      // удалили пропуски в списке разрешенных
    AllowedIPs:=StringReplace(AllowedIPs,'.','',[rfReplaceAll, rfIgnoreCase]);                      // убрали разделители в списке разрешенных
    AllowedIPs:=StringReplace(AllowedIPs,';',',',[rfReplaceAll, rfIgnoreCase]);                     // если разделители ; поменяли на запятые
    //---
    Result:=False;
    list:=TStringList.Create;
    list.CommaText:=AllowedIPs;                                                                     // залили список разрешенных в лист
    for i:=0 to list.Count-1 do begin
        ignore:=False;
        addr:=list[i];
        if( Pos('!',addr) = 1 )then begin                                                           // если нашли отрицание, то отметили
            ignore:=True;
            Delete(addr,1,1);
        end;
        //---
        found:=True;
        for ii:=1 to Length(addr)do begin                                                           // сравниваем строки посимвольно
            if( addr[ii] <> InConnectAddr[ii] )then begin
                if( addr[ii] <> '*' )then found:=False;                                             // нашли отличия запрещаем , если только это не знак разрешения всего
            end;
        end;
        //---
        if( not ignore )then Result:=found                                                          // если нет отрицания, то вовравращаем совпадение
            else Result:= not found;                                                                // если совпало по отрицанию - отрицаем
    end;
    //---
    list.Free;
end;
//-----------------------------------------------------------------------------+
function FileVersion(AFileName: string): string;
var
szName: array[0..255] of Char;
P: Pointer;
Value: Pointer;
Len: UINT;
GetTranslationString: string;
FFileName: PChar;
FValid: boolean;
FSize: DWORD;
FHandle: DWORD;
FBuffer: PChar;
begin
    FValid := False;
    try
        FFileName := StrPCopy(StrAlloc(Length(AFileName) + 1), AFileName);
        FSize := GetFileVersionInfoSize(FFileName, FHandle);
        if FSize > 0 then begin
            try
                GetMem(FBuffer, FSize);
                FValid := GetFileVersionInfo(FFileName, FHandle, FSize, FBuffer);
            except
                FValid := False;
                raise;
            end;
        end;
        Result := '';
        if FValid then VerQueryValue(FBuffer, '\VarFileInfo\Translation', p, Len) else p := nil;
        if P <> nil then GetTranslationString := IntToHex(MakeLong(HiWord(Longint(P^)), LoWord(Longint(P^))), 8);
        if FValid then begin
            StrPCopy(szName, '\StringFileInfo\' + GetTranslationString + '\FileVersion');
            if VerQueryValue(FBuffer, szName, Value, Len) then Result := StrPas(PChar(Value));
        end;
    finally
        try
            if FBuffer <> nil then
            FreeMem(FBuffer, FSize);
        except
        end;
        try
            StrDispose(FFileName);
        except
        end;
    end;
end;
//-----------------------------------------------------------------------------+
procedure ArrSort(var Data:array of Word; SortByDecrement:Boolean=False);overload;
var i,j,imax,imin,imid,fmin,fmax:Integer;
arr:array of Word;
begin
    SetLength(arr,Length(data)*2);
    //---
    imin :=Length(data);
    imax :=Length(data);
    imid:=0;
    arr[imin]:=data[0];
    //---
    for i:=1 to Length(data)-1 do begin
        Application.ProcessMessages;
        if( data[i] < arr[imin] )then begin
            Dec(imin);
            arr[imin]:=data[i];
        end else begin
            if( data[i] >= arr[imax] )then begin
                inc(imax);
                arr[imax]:=data[i];
            end else begin
                fmin:=imin;
                fmax:=imax;
                while( fmax-fmin > 32 )do begin
                    imid:=Trunc(fmin+(fmax-fmin)/2);
                    if( data[i] < arr[imid] )then fmax:=imid else fmin:=imid;
                end;
                for j:=fmax downto fmin do begin
                    if( data[i] < arr[j] )then Continue;
                    imid:=j;
                    Break;
                end;
                if( imid < Trunc((imin+imax)/2) )then begin
                    Move(arr[imin],arr[imin-1],(1+imid-imin)*sizeof(Word));
                    arr[imid]:=data[i];
                    Dec(imin);
                end else begin
                    Move(arr[imid+1],arr[imid+2],(1+imax-imid)*sizeof(Word));
                    arr[imid+1]:=data[i];
                    inc(imax);
                end;
            end;
        end;
    end;
    //---
    if( not SortByDecrement )then
        for i:=0 to Length(data)-1 do data[i]:=arr[i+imin]
        else for i:=0 to Length(data)-1 do data[i]:=arr[imax-i];
end;
//-----------------------------------------------------------------------------+
procedure ArrSort(var Data:array of Integer; SortByDecrement:Boolean=False);overload;
var i,j,imax,imin,imid,fmin,fmax:Integer;
arr:array of Integer;
begin
    SetLength(arr,Length(data)*2);
    //---
    imin :=Length(data);
    imax :=Length(data);
    imid:=0;
    arr[imin]:=data[0];
    //---
    for i:=1 to Length(data)-1 do begin
        Application.ProcessMessages;
        if( data[i] < arr[imin] )then begin
            Dec(imin);
            arr[imin]:=data[i];
        end else begin
            if( data[i] >= arr[imax] )then begin
                inc(imax);
                arr[imax]:=data[i];
            end else begin
                fmin:=imin;
                fmax:=imax;
                while( fmax-fmin > 32 )do begin
                    imid:=Trunc(fmin+(fmax-fmin)/2);
                    if( data[i] < arr[imid] )then fmax:=imid else fmin:=imid;
                end;
                for j:=fmax downto fmin do begin
                    if( data[i] < arr[j] )then Continue;
                    imid:=j;
                    Break;
                end;
                if( imid < Trunc((imin+imax)/2) )then begin
                    Move(arr[imin],arr[imin-1],(1+imid-imin)*sizeof(Integer));
                    arr[imid]:=data[i];
                    Dec(imin);
                end else begin
                    Move(arr[imid+1],arr[imid+2],(1+imax-imid)*sizeof(Integer));
                    arr[imid+1]:=data[i];
                    inc(imax);
                end;
            end;
        end;
    end;
    //---
    if( not SortByDecrement )then
        for i:=0 to Length(data)-1 do data[i]:=arr[i+imin]
        else for i:=0 to Length(data)-1 do data[i]:=arr[imax-i];
end;
//-----------------------------------------------------------------------------+Not Used
function ArrSortVar(var Data:array of Variant; sortByDecrement:Boolean=False):Boolean;
var VarSize:Integer;Variable:Variant;IsString:Boolean;
var i,j,imax,imin,imid,fmin,fmax:Integer;
arr:array of Variant;
begin
    VarSize:=0;
    IsString:=False;
    Result:=False;
    if( Length(Data) < 2 )then Exit;
    //---
    try
        Variable:=Data[0];
        if( VarIsNull(Variable) )then Exit;
        if( not VarIsStr(Variable) )then begin
            case TVarData(Variable).VType of
                //--- 1
                varShortInt,
                varByte     : VarSize:=SizeOf(Byte);
                //--- 2
                varSmallInt,
                varWord     : VarSize:=SizeOf(Word);
                //--- 4
                varSingle,
                varInteger,
                varLongWord : VarSize:=SizeOf(Integer);
                //--- 8
                varInt64,
                varUInt64,
                varCurrency,
                varDouble   : VarSize:=SizeOf(Int64);
            else
                VarSize:=0;
            end;
        end else IsString:=True;
    except
        on E : Exception do begin
            E:=nil;
            Exit;
        end;
    end;
    if( VarSize  = 0 )then Exit;
    //---
end;
//-----------------------------------------------------------------------------+
procedure ArrSort(var data:array of Int64; sortByDecrement:Boolean=False);overload;
var i,j,imax,imin,imid,fmin,fmax:Integer;
arr:array of int64;
begin
    SetLength(arr,Length(data)*2);
    for i:=0 to Length(arr)-1 do arr[i]:=0;
    //---
    imin :=Length(data);
    imax :=Length(data);
    imid :=0;
    arr[imin]:=data[0];
    //---
    for i:=1 to Length(data)-1 do begin
        Application.ProcessMessages;
        if( data[i] < arr[imin] )then begin
            Dec(imin);
            arr[imin]:=data[i];
        end else begin
            if( data[i] >= arr[imax] )then begin
                inc(imax);
                arr[imax]:=data[i];
            end else begin
                fmin:=imin;
                fmax:=imax;
                while( fmax-fmin > 32 )do begin
                    imid:=Trunc(fmin+(fmax-fmin)/2);
                    if( data[i] < arr[imid] )then fmax:=imid else fmin:=imid;
                end;
                for j:=fmax downto fmin do begin
                    if( data[i] < arr[j] )then Continue;
                    imid:=j;
                    Break;
                end;
                if( imid < Trunc((imin+imax)/2) )then begin
                    Move(arr[imin],arr[imin-1],(1+imid-imin)*sizeof(Int64));
                    arr[imid]:=data[i];
                    Dec(imin);
                end else begin
                    Move(arr[imid+1],arr[imid+2],(1+imax-imid)*sizeof(Int64));
                    arr[imid+1]:=data[i];
                    inc(imax);
                end;
            end;
        end;
    end;
    //---
    if( not SortByDecrement )then
        for i:=0 to Length(data)-1 do data[i]:=arr[i+imin]
        else for i:=0 to Length(data)-1 do data[i]:=arr[imax-i];
end;
//-----------------------------------------------------------------------------+
procedure ArrSort(var data:array of Double; sortByDecrement:Boolean=False);overload;
var i,j,imax,imin,imid,fmin,fmax:Integer;
arr:array of Double;
begin
    SetLength(arr,Length(data)*2);
    for i:=0 to Length(arr)-1 do arr[i]:=0;
    //---
    imin :=Length(data);
    imax :=Length(data);
    imid :=0;
    arr[imin]:=data[0];
    //---
    for i:=1 to Length(data)-1 do begin
        Application.ProcessMessages;
        if( data[i] < arr[imin] )then begin
            Dec(imin);
            arr[imin]:=data[i];
        end else begin
            if( data[i] >= arr[imax] )then begin
                inc(imax);
                arr[imax]:=data[i];
            end else begin
                fmin:=imin;
                fmax:=imax;
                while( fmax-fmin > 32 )do begin
                    imid:=Trunc(fmin+(fmax-fmin)/2);
                    if( data[i] < arr[imid] )then fmax:=imid else fmin:=imid;
                end;
                for j:=fmax downto fmin do begin
                    if( data[i] < arr[j] )then Continue;
                    imid:=j;
                    Break;
                end;
                if( imid < Trunc((imin+imax)/2) )then begin
                    Move(arr[imin],arr[imin-1],(1+imid-imin)*sizeof(Double));
                    arr[imid]:=data[i];
                    Dec(imin);
                end else begin
                    Move(arr[imid+1],arr[imid+2],(1+imax-imid)*sizeof(Double));
                    arr[imid+1]:=data[i];
                    inc(imax);
                end;
            end;
        end;
    end;
    //---
    if( not SortByDecrement )then
        for i:=0 to Length(data)-1 do data[i]:=arr[i+imin]
        else for i:=0 to Length(data)-1 do data[i]:=arr[imax-i];
end;
//-----------------------------------------------------------------------------+
procedure ArrSort(var data:array of ShortString; sortByDecrement:Boolean=False);overload;
var i,j,imax,imin,imid,fmin,fmax:Integer;
arr:array of ShortString;
begin
    SetLength(arr,Length(data)*2);
    for i:=0 to Length(arr)-1 do arr[i]:='';
    //---
    imin :=Length(data);
    imax :=Length(data);
    imid :=0;
    arr[imin]:=data[0];
    //---
    for i:=1 to Length(data)-1 do begin
        Application.ProcessMessages;
        if( data[i] < arr[imin] )then begin
            Dec(imin);
            arr[imin]:=data[i];
        end else begin
            if( data[i] >= arr[imax] )then begin
                inc(imax);
                arr[imax]:=data[i];
            end else begin
                fmin:=imin;
                fmax:=imax;
                while( fmax-fmin > 32 )do begin
                    imid:=Trunc(fmin+(fmax-fmin)/2);
                    if( data[i] < arr[imid] )then fmax:=imid else fmin:=imid;
                end;
                for j:=fmax downto fmin do begin
                    if( data[i] < arr[j] )then Continue;
                    imid:=j;
                    Break;
                end;
                if( imid < Trunc((imin+imax)/2) )then begin
                    Move(arr[imin],arr[imin-1],(1+imid-imin)*sizeof(ShortString));
                    arr[imid]:=data[i];
                    Dec(imin);
                end else begin
                    Move(arr[imid+1],arr[imid+2],(1+imax-imid)*sizeof(ShortString));
                    arr[imid+1]:=data[i];
                    inc(imax);
                end;
            end;
        end;
    end;
    //---
    if( not SortByDecrement )then
        for i:=0 to Length(data)-1 do data[i]:=arr[i+imin]
        else for i:=0 to Length(data)-1 do data[i]:=arr[imax-i];
end;
//-----------------------------------------------------------------------------+
procedure ArrSort(var data:array of AnsiString; sortByDecrement:Boolean=False);overload;
var i,j,imax,imin,imid,fmin,fmax:Integer;
arr:array of ShortString;
begin
    SetLength(arr,Length(data)*2);
    for i:=0 to Length(arr)-1 do arr[i]:='';
    //---
    imin :=Length(data);
    imax :=Length(data);
    imid :=0;
    arr[imin]:=data[0];
    //---
    for i:=1 to Length(data)-1 do begin
        Application.ProcessMessages;
        if( data[i] < arr[imin] )then begin
            Dec(imin);
            arr[imin]:=data[i];
        end else begin
            if( data[i] >= arr[imax] )then begin
                inc(imax);
                arr[imax]:=data[i];
            end else begin
                fmin:=imin;
                fmax:=imax;
                while( fmax-fmin > 32 )do begin
                    imid:=Trunc(fmin+(fmax-fmin)/2);
                    if( data[i] < arr[imid] )then fmax:=imid else fmin:=imid;
                end;
                for j:=fmax downto fmin do begin
                    if( data[i] < arr[j] )then Continue;
                    imid:=j;
                    Break;
                end;
                if( imid < Trunc((imin+imax)/2) )then begin
                    for j:=imin to imid do arr[j-1]:=arr[j];
                    arr[imid]:=data[i];
                    Dec(imin);
                end else begin
                    for j:=imax downto imid+1 do arr[j+1]:=arr[j];
                    arr[imid+1]:=data[i];
                    inc(imax);
                end;
            end;
        end;
    end;
    //---
    if( not SortByDecrement )then
        for i:=0 to Length(data)-1 do data[i]:=arr[i+imin]
        else for i:=0 to Length(data)-1 do data[i]:=arr[imax-i];
end;
//-----------------------------------------------------------------------------+

//-----------------------------------------------------------------------------+
procedure FlipFlop(var data:array of Integer; val:Integer; var min,max:Integer);
var i:Integer;
begin
    i:=max-Trunc((max-min)/2);
    //--- flip
    while( val < data[i] )do begin
        max:=i;
        i:=Trunc(i/2);
        if( i < min )then Exit;
    end;
    min:=i;
    //--- flop
    while( val > data[i] )do begin
        min:=i;
        i:=i+Trunc((max-i)/2)+1;
        if( i > max )then Exit;     
    end;
    max:=i;
end;
//-----------------------------------------------------------------------------+
end.
