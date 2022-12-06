unit principal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Horse, System.JSON, gtPDFPrinter,
  Horse.Jhonson,
  Vcl.StdCtrls, gtPDFClasses, gtCstPDFDoc, gtExPDFDoc, gtExProPDFDoc, gtPDFDoc,
  System.NetEncoding,
  Horse.CORS, ShellApi, Vcl.ExtCtrls, JvComponentBase, JvTrayIcon, IniFiles;

type
  TForm1 = class(TForm)
    gtPDFPrinter1: TgtPDFPrinter;
    Memo1: TMemo;
    gtPDFDocument1: TgtPDFDocument;
    JvTrayIcon1: TJvTrayIcon;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  data: TInifile;
  porta: String;

implementation

{$R *.dfm}

function quebra(BaseString, BreakString: string; StringList: TStringList)
  : TStringList;
var
  EndOfCurrentString: byte;
  TempStr: string;
begin

  repeat
    EndOfCurrentString := Pos(BreakString, BaseString);
    if EndOfCurrentString = 0 then
      StringList.add(BaseString)
    else
      StringList.add(Copy(BaseString, 1, EndOfCurrentString - 1));
    BaseString := Copy(BaseString, EndOfCurrentString + length(BreakString),
      length(BaseString) - EndOfCurrentString);

  until EndOfCurrentString = 0;
  result := StringList;
end;

procedure ExecuteAndWait(const aCommando: string);
var
  tmpStartupInfo: TStartupInfo;
  tmpProcessInformation: TProcessInformation;
  tmpProgram: String;
begin

  tmpProgram := trim(aCommando);
  FillChar(tmpStartupInfo, SizeOf(tmpStartupInfo), 0);
  with tmpStartupInfo do
  begin
    cb := SizeOf(TStartupInfo);
    wShowWindow := SW_HIDE;
  end;

  if CreateProcess(nil, pchar(tmpProgram), nil, nil, true, CREATE_NO_WINDOW,
    nil, nil, tmpStartupInfo, tmpProcessInformation) then
  begin
    // loop every 10 ms
    while WaitForSingleObject(tmpProcessInformation.hProcess, 10) > 0 do
    begin
      Application.ProcessMessages;
    end;
    CloseHandle(tmpProcessInformation.hProcess);
    CloseHandle(tmpProcessInformation.hThread);
  end
  else
  begin
    RaiseLastOSError;
  end;
end;
procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caNone;
end;
procedure TForm1.FormCreate(Sender: TObject);

begin
  // Para criar o arquivo INI:
  // data := TInifile.Create(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  // Nome do meu arquivo INI que será criado
  // data.WriteString('CONFIGURACAO', 'PORTA', '8000');
  // O conteúdo do Edit1.Text será gravado dentro da chave CONFIGURACAO e na subchave PORTA
  // data.Free; // Libera a memória

  // Para ler o arquivo INI:
  data := TInifile.Create(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  // Nome do meu arquivo INI que quero ler
  porta := data.ReadString('CONFIGURACAO', 'PORTA', '');
  // O Edit1.Text vai receber o que está gravado dentro da chave NOME1 e da subchave NOME2
  data.Free; // Libera a memória

  THorse.Use(Jhonson);
  THorse.Use(CORS);

  THorse.Get('/printers',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Impressoras: TJSONArray;
      i: integer;
    begin
      Impressoras := TJSONArray.Create;

      for i := 0 to gtPDFPrinter1.GetInstalledPrinters.count - 1 do
      begin

        Impressoras.add(TJSONObject.Create.AddPair('impressora',
          gtPDFPrinter1.GetInstalledPrinters[i]));

      end;

      Res.Send(Impressoras);

    end);

  THorse.Post('/print',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      lBody, lRetorno: TJSONObject;
      tipo: String;
      impressora: String;
      base64: String;
      data_hora: String;
      usuario: String;
      id_pdf: String;
      stream: TBytesStream;
      arquivo: TStringList;
      f: textfile;
      OutPutList: TStringList;
      i: integer;
    begin

      lBody := Req.Body<TJSONObject>;

      tipo := lBody.Values['type'].Value;
      impressora := lBody.Values['printer'].Value;
      base64 := lBody.Values['base64'].Value;
      data_hora := lBody.Values['data_hora'].Value;
      usuario := lBody.Values['usuario'].Value;
      id_pdf := lBody.Values['id_pdf'].Value;

      Memo1.Lines.add(data_hora + ' |' + usuario + ' |' + impressora);
      Memo1.Lines.add('\Docs\' + id_pdf + '.pdf "' + impressora + '"');
      if tipo = 'PDF' then
      begin

        stream := TBytesStream.Create
          (TNetEncoding.base64.DecodeStringToBytes(base64));

        stream.SaveToFile(ExtractFilePath(ParamStr(0)) + '\Docs\' + id_pdf
          + '.pdf');

        ShellExecute(Handle, 'open', pchar('PDFtoPrinter.exe'),
          pchar('"' + ExtractFilePath(ParamStr(0)) + '' + 'Docs\' + id_pdf +
          '.pdf" "' + impressora + '"'), nil, SW_HIDE);
        //Memo1.Lines.add('"' + ExtractFilePath(ParamStr(0)) + '' + 'Docs\' + id_pdf + '.pdf" "' + impressora + '"' + '"' + ExtractFilePath(ParamStr(0)) + 'Config.ini"');

        lRetorno := TJSONObject.Create;
        lRetorno.AddPair('status', 'true');

      end;

      Res.Send(lRetorno);

    end);

  THorse.Listen(Strtoint(porta));
end;

end.
