unit UDownThread;

interface

uses
  Classes, Windows, SysUtils, IdHTTP, IdComponent, Math, Messages;

const
  WM_DownProgres = WM_USER + 1001;

type
  TDownThread = class(TThread)
  private
    FIDHttp: TIdHTTP;
    FMaxProgres: Int64;
    FMs: TMemoryStream;
    FURL: string;
    FSavePath: string;
    FHandle: THandle;
    FileSize, FilePosition: Int64;
    { Private declarations }
    procedure DoExecute;
    procedure DoWorkBegin(ASender: TObject; AWorkMode: TWorkMode;
      AWorkCountMax: Int64);
    procedure DoWork(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
  protected
    procedure Execute; override;
  public
    ID: string;
    constructor Create(AURL, ASavePath: string; AHandle: THandle);
    destructor Destroy; override;
  end;

implementation

{ uDownThread }

constructor TDownThread.Create(AURL, ASavePath: string; AHandle: THandle);
begin
  FURL := AURL;
  FSavePath := ASavePath;
  FHandle := AHandle;
  FIDHttp := TIdHTTP.Create(nil);
  FIDHttp.HandleRedirects:=True;
  FIDHttp.Request.Accept := 'image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, application/x-shockwave-flash, */*';
  FIDHttp.Request.AcceptLanguage := 'zh-cn';
  FIDHttp.Request.ContentType := 'application/x-www-form-urlencoded';
  FIDHttp.Request.UserAgent := 'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1) ; .NET CLR 2.0.50727; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022)';
  FIDHttp.ReadTimeout:= 60000;
  FIDHttp.OnWorkBegin := DoWorkBegin;
  FIDHttp.OnWork := DoWork;
  inherited Create(False); // ²ÎÊýÎªFalseÖ¸Ïß³Ì´´½¨ºó×Ô¶¯ÔËÐÐ,ÎªTrueÔò²»×Ô¶¯ÔËÐÐ
  FreeOnTerminate := True; // Ö´ÐÐÍê±Ïºó×Ô¶¯ÊÍ·Å
end;

destructor TDownThread.Destroy;
begin
  PostMessage(FHandle, WM_DownProgres, Integer(ID), 100);
  FIDHttp.Free;
  FMs.Free;
  inherited;
end;

procedure TDownThread.DoExecute;
const
  RECV_BUFFER_SIZE = 512000;//102400;
var
  DownCount: Integer;
begin
    FMs := TMemoryStream.Create;

    FIDHttp.Head(FURL);
    FileSize := FIDHttp.Response.ContentLength;
    FilePosition:=0;
    DownCount := 0;

    while FilePosition < FileSize do
    begin
      Inc(DownCount);
      FIDHttp.Request.Range := IntToStr(FilePosition) + '-' ;
      if FilePosition + RECV_BUFFER_SIZE < FileSize then
        FIDHttp.Request.Range := FIDHttp.Request.Range + IntToStr(FilePosition + (RECV_BUFFER_SIZE-1));

      FIDHttp.Get(FIDHttp.URL.URI, FMs); // wait until it is done
      FMs.SaveToFile(FSavePath);
      FilePosition := FMs.Size;

      if (DownCount=1) and (FilePosition>RECV_BUFFER_SIZE) then Break;
    end;
//
//    FIDHttp.Get(FURL, FMs);
//    FMs.SaveToFile(FSavePath);
end;

procedure TDownThread.DoWork(ASender: TObject; AWorkMode: TWorkMode;
  AWorkCount: Int64);
var
  ANowProgres: Integer;
begin
  if FMaxProgres <> 0 then
  begin
//    ANowProgres := Ceil(AWorkCount / FMaxProgres * 100);
//    PostMessage(FHandle, WM_DownProgres, 0, ANowProgres);
    ANowProgres := Ceil(FMs.Size / FileSize * 100);
    if ANowProgres<100 then
      PostMessage(FHandle, WM_DownProgres, Integer(ID), ANowProgres);
  end;
end;

procedure TDownThread.DoWorkBegin(ASender: TObject; AWorkMode: TWorkMode;
  AWorkCountMax: Int64);
begin
  FMaxProgres := AWorkCountMax;
end;

procedure TDownThread.Execute;
begin
  DoExecute;
end;


end.
