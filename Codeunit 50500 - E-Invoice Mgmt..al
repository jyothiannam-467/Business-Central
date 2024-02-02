codeunit 50007 "E-Invoice Mgmt."
{
    // version E-INV,TokenExpiryFix,E-INVB2C
    Permissions = tabledata "E-Invoice Entry" = RMDI, tabledata "E-Invoice Log" = RMDI, tabledata "Sales Invoice Header" = RM;
    trigger OnRun();
    var
        RequestFail: Boolean;
        EInvoiceSetup: Record "E-Invoice Setup";
    begin
        EInvoiceSetup.GET;
        CASE EInvoiceSetup."GSP Priority" OF
            EInvoiceSetup."GSP Priority"::Adequre:
                BEGIN
                    IF NOT TriggerEInvoiceAdequre THEN
                        //IF NOT TriggerEinvoiceMI THEN
                            MESSAGE('%1', GETLASTERRORTEXT);
                END;
            EInvoiceSetup."GSP Priority"::MI:
                BEGIN
                    IF NOT TriggerEinvoiceMI THEN
                        //IF NOT TriggerEInvoiceAdequre THEN
                            MESSAGE('%1', GETLASTERRORTEXT);
                END;
        END;
    end;

    var
        HttpWebRequest: DotNet HttpWebRequestDV;
        HttpWebResponse: DotNet HttpWebResponseDV;
        HttpRequestMessageG: HttpRequestMessage;
        HttpResponseMessageG: HttpResponseMessage;
        HttpHeadersG: HttpHeaders;
        HttpClientG: HttpClient;
        HttpContentG: HttpContent;
        HeadersG: HttpHeaders;
        JobjG: JsonObject;
        ResponseG: Text;
        ExpiresInG: Integer;
        JTokenGAc: JsonToken;
        JTokenExp: JsonToken;

        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
        IsInvoice: Boolean;
        EInvFailTxt: Label 'E-%1 Upload failed With message : %2';
        EInvSuccessTxt: Label 'E-%1 Uploaded With message : %2';
        SuccessTxt: Label 'E-Invoice generated.';
        EInvoiceEntry: Record "E-Invoice Entry";
        GetEInvFailTxt: Label 'Get eInvoice by IRN failed With message : %1';
        JsonPath: Text;
        CreidtMemo: Boolean;
        TransferShipment: Boolean;
        TransferShipmentHeader: Record "Transfer Shipment Header";
        BatchPosting: Boolean;

    local procedure TriggerEInvoiceAdequre(): Boolean;
    begin
        IF NOT GenerateAccessToken THEN
            EXIT(FALSE);
        IF NOT SalesEInvoice THEN
            EXIT(FALSE);
        //SalesEInvoice();
        EXIT(TRUE);
    end;

    local procedure TriggerEinvoiceMI(): Boolean;
    begin
        IF NOT GenerateAccessTokenMI THEN
            EXIT(FALSE);
        IF NOT SalesEInvoiceMI THEN
            EXIT(FALSE);
        EXIT(TRUE);
    end;

    procedure CancelIRN(Variant: Variant);
    var
        EInvoiceSetup: Record "E-Invoice Setup";
    begin
        EInvoiceSetup.GET;
        CASE EInvoiceSetup."GSP Priority" OF
            EInvoiceSetup."GSP Priority"::Adequre:
                BEGIN
                    IF NOT TriggerCancelIRNAdequre(Variant) THEN
                        IF NOT TriggerCancelIRNMI(Variant) THEN
                            if not BatchPosting then
                                MESSAGE('%1', GETLASTERRORTEXT);
                END;
            EInvoiceSetup."GSP Priority"::MI:
                BEGIN
                    IF NOT TriggerCancelIRNMI(Variant) THEN
                        IF NOT TriggerCancelIRNAdequre(Variant) THEN
                            if not BatchPosting then
                                MESSAGE('%1', GETLASTERRORTEXT);
                END;
        END;
    end;

    local procedure TriggerCancelIRNAdequre(Variant: Variant): Boolean;
    begin
        IF NOT GenerateAccessToken THEN
            EXIT(FALSE);
        IF NOT CancelIRNAdequre(Variant) THEN
            EXIT(FALSE);
        EXIT(TRUE);
    end;

    local procedure TriggerCancelIRNMI(Variant: Variant): Boolean;
    var
        RecRef: RecordRef;
    begin
        RecRef.GETTABLE(Variant);
        CASE RecRef.NUMBER OF
            112:
                SetSalesInvHeader(Variant);
            114:
                SetCrMemoHeader(Variant);
        END;

        IF NOT GenerateAccessTokenMI THEN
            EXIT(FALSE);
        IF NOT CancelIrnMI(Variant) THEN
            EXIT(FALSE);
        EXIT(TRUE);
    end;

    local procedure GenerateAccessToken(): Boolean;
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        AccessCode: Text;
        //AccessCodeDll: DotNet AccessCodeDllDV;
        Input: Text;
        Result: Text;
        EInvoiceLog: Record "E-Invoice Log";
        EInvoiceSetup: Record "E-Invoice Setup";
        FileMgmt: Codeunit "File Management";
    begin
        EInvoiceSetup.GET;
        IF EInvoiceSetup."Access Token Expiry Date" <> 0DT THEN//TokenExpiryFix
            IF EInvoiceSetup."Access Token Expiry Date" > CURRENTDATETIME THEN//TokenExpiryFix
                EXIT(TRUE);
        //Generate Access Code >>
        //  AccessCodeDll := AccessCodeDll.GenerateAccessToken();
        // AccessCodeDll.AccessToken(Input, Result, AccessCode);
        //B2BSaas>>
        HeadersG := HttpClientG.DefaultRequestHeaders;
        HeadersG.Add('gspappid', EInvoiceSetup."Client ID");
        HttpRequestMessageG.GetHeaders(HeadersG);
        HeadersG.Clear();
        HeadersG.Add('gspappsecret', EInvoiceSetup."Client Secret");
        HttpRequestMessageG.SetRequestUri('https://gsp.adaequare.com/gsp/authenticate?grant_type=token');
        HttpRequestMessageG.Method := 'POST';
        HttpRequestMessageG.Content := HttpContentG;
        HttpClientG.Send(HttpRequestMessageG, HttpResponseMessageG);
        HttpResponseMessageG.Content.ReadAs(ResponseG);
        JobjG := ReadJSONAcctoken(ResponseG);
        JobjG.Get('access_token', JTokenGAc);
        AccessCode := JTokenGAc.AsValue().AsText();
        JobjG.Get('expires_in', JTokenExp);
        ExpiresInG := JTokenExp.AsValue().AsInteger();
        Input := ResponseG;
        //B2BSaas<<


        EInvoiceLog.INIT;
        EInvoiceLog."Document Type" := EInvoiceLog."Document Type"::"Access Token";
        EInvoiceLog."Document No." := 'AccessToken';
        EInvoiceLog."Date & Time" := CURRENTDATETIME;
        EInvoiceLog."User Id" := USERID;

        EInvoiceLog."Response Path" := EInvoiceSetup."Access Token Response Path" + 'AccessTokenResponse' +
                                            DELCHR(FORMAT(TODAY), '=', '/\_*^@') + '.Json';//TokenExpiryFix
                                                                                           // IF Result <> 'Success' THEN
        if not HttpResponseMessageG.IsSuccessStatusCode then
            EInvoiceLog.Status := EInvoiceLog.Status::Failed;
        EInvoiceLog.INSERT(true);
        if FILE.Exists(EInvoiceLog."Response Path") then
            File.Erase(EInvoiceLog."Response Path");
        CLEAR(TempBlob);
        TempBlob.CREATEOUTSTREAM(OutStr);
        OutStr.WRITETEXT(Input);
        //TempBlob.EXPORT(EInvoiceLog."Response Path"); //B2BUPG1.0
        FileMgmt.BLOBExportToServerFile(TempBlob, EInvoiceLog."Response Path");

        EInvoiceSetup."Access Token Expiry Date" := GetTokenExpiryFromResponse(Input);//TokenExpiryFix

        IF EInvoiceLog.Status = EInvoiceLog.Status::Failed THEN
            EXIT(FALSE);

        //AccessCode := ReadAccessToken(Input);//Will fetch Access Token
        EInvoiceSetup."Access Token Date" := CURRENTDATETIME;
        EInvoiceSetup."Access Token" := COPYSTR(AccessCode, 1, MAXSTRLEN(EInvoiceSetup."Access Token"));
        EInvoiceSetup."Access Token 2" := COPYSTR(AccessCode, MAXSTRLEN(EInvoiceSetup."Access Token") + 1, MAXSTRLEN(EInvoiceSetup."Access Token 2"));
        EInvoiceSetup.MODIFY;

        EXIT(TRUE);
    end;

    //[TryFunction]
    local procedure SalesEInvoice(): Boolean;
    var
        FileManagement: Codeunit 419;
        FileStream: DotNet FileStream;
        FileMode: DotNet FileMode;
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        EInvoiceRequestAdequre: Codeunit "E-Invoice Request -Adequre";
        EInvoiceLog: Record "E-Invoice Log";
        EInvoiceSetup: Record "E-Invoice Setup";
        GUIDStorage: Text;
        ResponseFileName: Text;
        Location: Record Location;
        UserName: Text;
        Password: Text;
        GSTIN: Code[15];
        //Test: Record Test;
        EValidate: Codeunit "Validate E-Invoice Request";
        ResponseLVar: Text;
    begin
        //TestFun();
        EInvoiceSetup.GET;
        IF IsInvoice THEN BEGIN
            // Generating JSON  >>
            EInvoiceRequestAdequre.SetSalesInvHeader(SalesInvHeader);
            EInvoiceRequestAdequre.RUN;
            //EInvoiceRequestAdequre.GetRequestPath(JsonPath);
            // Generating JSON  <<
            EInvoiceLog.RESET;
            EInvoiceLog.SETRANGE("Document No.", SalesInvHeader."No.");
            EInvoiceLog.SETRANGE("Document Type", EInvoiceLog."Document Type"::Invoice);
            EInvoiceLog.FINDLAST;

            ResponseFileName := EInvoiceSetup."JSON Response Path" +
                                DELCHR(SalesInvHeader."No." + '_' + FORMAT(CURRENTDATETIME), '=', '/\:-*^@') + '_Response' + '.Json';

            Location.GET(SalesInvHeader."Location Code");
        END ELSE
            IF CreidtMemo THEN BEGIN
                // Generating JSON  >>
                EInvoiceRequestAdequre.SetCrMemoHeader(SalesCrMemoHdr);
                EInvoiceRequestAdequre.RUN;
                // Generating JSON  <<
                EInvoiceLog.RESET;
                EInvoiceLog.SETRANGE("Document Type", EInvoiceLog."Document Type"::"Credit Memo");
                EInvoiceLog.SETRANGE("Document No.", SalesCrMemoHdr."No.");
                EInvoiceLog.FINDLAST;

                ResponseFileName := EInvoiceSetup."JSON Response Path" +
                                    DELCHR(SalesCrMemoHdr."No." + '_' + FORMAT(CURRENTDATETIME), '=', '/\:-*^@') + '_Response' + '.Json';

                Location.GET(SalesCrMemoHdr."Location Code");
            END ELSE
                IF TransferShipment THEN BEGIN
                    // Generating JSON  >>
                    EInvoiceRequestAdequre.SetTransferShipmentHeader(TransferShipmentHeader);
                    EInvoiceRequestAdequre.RUN;
                    // Generating JSON  <<
                    EInvoiceLog.RESET;
                    EInvoiceLog.SETRANGE("Document Type", EInvoiceLog."Document Type"::"Transfer Shipment");
                    EInvoiceLog.SETRANGE("Document No.", TransferShipmentHeader."No.");
                    EInvoiceLog.FINDLAST;

                    ResponseFileName := EInvoiceSetup."JSON Response Path" +
                                        DELCHR(TransferShipmentHeader."No." + '_' + FORMAT(CURRENTDATETIME), '=', '/\:-*^@') + '_Response' + '.Json';

                    Location.GET(TransferShipmentHeader."Transfer-from Code");
                END;

        Location.TESTFIELD("User Name");
        Location.TESTFIELD(Password);

        UserName := Location."User Name";
        Password := Location.Password;
        GSTIN := Location."GST Registration No.";
        GUIDStorage := CREATEGUID;

        //E-Invoice API Connection >>
        HttpWebRequest := HttpWebRequest.Create(EInvoiceSetup."Request URL");
        HttpWebRequest.Method := 'POST';

        HttpWebRequest.Headers.Add('user_name', UserName);
        HttpWebRequest.Headers.Add('password', Password);
        HttpWebRequest.Headers.Add('gstin', GSTIN);
        HttpWebRequest.Headers.Add('requestid', GUIDStorage);
        HttpWebRequest.Headers.Add('Authorization', 'bearer ' + EInvoiceSetup."Access Token" + EInvoiceSetup."Access Token 2");
        //E-Invoice API Connection <<

        //Attaching Body >>
        EInvoiceLog.TESTFIELD("Request Path");
        FileStream := FileStream.FileStream(EInvoiceLog."Request Path", FileMode.Open);
        FileStream.CopyTo(HttpWebRequest.GetRequestStream);
        // Attaching Body <<
        HttpWebResponse := HttpWebRequest.GetResponse();
        InStr := HttpWebResponse.GetResponseStream();
        InStr.ReadText(ResponseLVar);
        InStr := HttpWebResponse.GetResponseStream;

        CLEAR(TempBlob);
        TempBlob.CREATEOUTSTREAM(OutStr);
        OutStr.WriteText(ResponseLVar);
        //  COPYSTREAM(OutStr, InStr);
        //TempBlob.EXPORT(ResponseFileName);
        //FileManagement.BLOBExport(TempBlob, ResponseFileName, true); //B2BUPG1.0
        FileManagement.BLOBExportToServerFile(TempBlob, ResponseFileName);
        IF HttpWebResponse.StatusCode <> 200 THEN
            EXIT(false);

        EInvoiceLog."Request GUID" := GUIDStorage;
        EInvoiceLog."Response Path" := ResponseFileName;
        EInvoiceLog."User Id" := USERID;
        // Read Json and Update Posted Document response
        ReadResponseJSON(ResponseLVar, EInvoiceLog);

        EInvoiceLog.MODIFY;
        if not BatchPosting then
            IF EInvoiceLog.Status = EInvoiceLog.Status::Failed THEN begin
                MESSAGE(EInvFailTxt, FORMAT(EInvoiceLog."Document Type"), EInvoiceLog."Request/Response Code");
                exit(false);
            end ELSE begin
                MESSAGE(SuccessTxt);
                exit(true);
            end;
    end;

    /*  local procedure CreateQRCode(QRCodeInput: Text; var TempBLOBPar: Codeunit "Temp Blob");
      var
          FileManagement: Codeunit 419;
          QRCodeFileName: Text;
      begin
          CLEAR(TempBLOBPar);
          QRCodeFileName := GetQRCode(QRCodeInput);
          FileManagement.BLOBImportFromServerFile(TempBLOBPar, QRCodeFileName);
          DeleteServerFile(QRCodeFileName);
      end;

      local procedure GetQRCode(QRCodeInput: Text) QRCodeFileName: Text;
      var
          IBarCodeProvider: DotNet IBarCodeProviderDV;
      begin
          GetBarCodeProvider(IBarCodeProvider);
          QRCodeFileName := IBarCodeProvider.GetBarcode(QRCodeInput);
      end;

      local procedure GetBarCodeProvider(var IBarCodeProvider: DotNet IBarCodeProviderDV);
      var
          QRCodeProvider: DotNet QRCodeProviderDV;
      begin
          //IF ISNULL(IBarCodeProvider) THEN
          //IBarCodeProvider := QRCodeProvider.QRCodeProvider;

          CLEAR(QRCodeProvider);
          QRCodeProvider := QRCodeProvider.QRCodeProvider;
          IBarCodeProvider := QRCodeProvider;
      end;*/

    local procedure DeleteServerFile(ServerFileName: Text);
    begin
        IF ERASE(ServerFileName) THEN;
    end;

    procedure SetSalesInvHeader(SalesInvoiceHeaderBuff: Record "Sales Invoice Header");
    begin
        SalesInvHeader := SalesInvoiceHeaderBuff;
        IsInvoice := TRUE;
        EInvoiceEntry.GET(EInvoiceEntry."Document Type"::"Sales Invoice", SalesInvHeader."No.");
    end;

    procedure SetCrMemoHeader(SalesCrMemoHeaderBuff: Record "Sales Cr.Memo Header");
    begin
        SalesCrMemoHdr := SalesCrMemoHeaderBuff;
        IsInvoice := FALSE;
        CreidtMemo := true;
        EInvoiceEntry.GET(EInvoiceEntry."Document Type"::"Sales Cr. Memo", SalesCrMemoHdr."No.");
    end;

    procedure SetTransferShipHeader(TransferShipmentHeaderBuff: Record "Transfer Shipment Header");
    begin
        TransferShipmentHeader := TransferShipmentHeaderBuff;
        TransferShipment := TRUE;
        EInvoiceEntry.GET(EInvoiceEntry."Document Type"::"Transfer Shipment", TransferShipmentHeader."No.");
    end;

    /*procedure ReadAccessToken(JSONText: Text) AccessCode: Text;
    var
        JSONTextReader: DotNet JsonTextReader;
        StringReader: DotNet StringReader;
        TokenType: Integer;
        Jav: DotNet Serialization;
        Dir: DotNet GenDictionary;
        Dir2: DotNet GenDictionary;
    begin
        Jav := Jav.JavaScriptSerializer;
        Dir := Jav.DeserializeObject(JSONText);
        //Dir.TryGetValue('access_token',AccessCode);
        //AccessCode := 'bearer'+ AccessCode;
    end;*/

    procedure GetTokenExpiryFromResponse(ResponseL: text) ReturnDate: DateTime;
    var
        Days: Integer;
        Hours: Integer;
        Mins: Integer;
        Secs: Integer;
        ExpiryDate: Date;
        ExpiryTime: Time;
        JSONText: Text;
        ResponseValue: Variant;
        InstreamL: InStream;
        OutstreamL: OutStream;
        ExpiresInl: Integer;
        JobjL: JsonObject;
        JTokenExp: JsonToken;
        ExpiryDuration: Integer;
    begin
        //>>TokenExpiryFix
        JobjL := ReadJSONAcctoken(ResponseL);
        JobjL.Get('expires_in', JTokenExp);
        ExpiryDuration := JTokenExp.AsValue().AsInteger();
        // ExpiryDuration := ResponseValue;
        Days := ExpiryDuration DIV (60 * 60 * 24);
        ExpiryDuration := ExpiryDuration MOD (60 * 60 * 24);
        Hours := ExpiryDuration DIV (60 * 60);
        ExpiryDuration := ExpiryDuration MOD (60 * 60);
        Mins := ExpiryDuration DIV (60);
        Secs := ExpiryDuration MOD (60);
        IF Days > 0 THEN
            ExpiryDate := CALCDATE(FORMAT(Days) + 'D', TODAY)
        ELSE
            ExpiryDate := TODAY;
        EVALUATE(ExpiryTime, FORMAT(Hours) + ':' + FORMAT(Mins) + ':' + FORMAT(Secs));
        EXIT(CREATEDATETIME(ExpiryDate, ExpiryTime));
        //<<TokenExpiryFix
    end;

    Procedure ReadJSONAcctoken(Data: Text) Result: JsonObject
    begin
        Result.ReadFrom(Data);
    end;

    procedure ReadResponseJSON(ResponseL: Text; var EInvoiceLog: Record "E-Invoice Log")
    var
        JSONOBJL: JsonObject;
        SuccessL: Boolean;
        RecRef: RecordRef;
        FieldRef: FieldRef;
        BigInt: BigInteger;
        AckDate: DateTime;
        QRText: Text;
        IRN: Text;
        TempBlob2: Codeunit "Temp Blob";
        Success: Boolean;
        ResultL: Text;
        JSTokenRes: JsonToken;
        messageL: Text;
        JSONOBJ2: JsonObject;
        JSTOken2: JsonToken;
        QrCode: Codeunit "QR Generator";
        OutstreamL: OutStream;
        InstreamL: InStream;
        AckDate1: Text;
        MessageTxt: text;

    begin

        JSONOBJL := ReadJson(ResponseL);
        if JSONOBJL.Get('success', JSTokenRes) then
            Success := JSTokenRes.AsValue().AsBoolean();
        Clear(JSTokenRes);

        if JSONOBJL.Get('message', JSTokenRes) then
            messageL := JSTokenRes.AsValue().AsText();
        Clear(JSTokenRes);

        if Success then begin
            JSONOBJL.Get('result', JSTokenRes);
            if JSTokenRes.IsObject() then begin
                JSTokenRes.WriteTo(ResultL);
                JSONOBJ2.ReadFrom(ResultL);

                JSONOBJ2.Get('AckNo', JSTOken2);
                BigInt := JSTOken2.AsValue().AsBigInteger();
                Clear(JSTOken2);

                JSONOBJ2.Get('AckDt', JSTOken2);
                // Evaluate(AckDate1,format(JSTOken2.AsValue()));
                AckDate1 := JSTOken2.AsValue().AsText();
                Clear(JSTOken2);
                AckDate := GetDateTimeFromText(FORMAT(AckDate1));

                JSONOBJ2.Get('Irn', JSTOken2);
                IRN := JSTOken2.AsValue().AsText();
                Clear(JSTOken2);

                JSONOBJ2.Get('SignedQRCode', JSTOken2);
                QRText := JSTOken2.AsValue().AsText();
                QrCode.GenerateQRCodeImage(QRText, TempBlob2);
            end;
            if IsInvoice then begin
                RecRef.GetTable(SalesInvHeader);
                FieldRef := RecRef.Field(SalesInvHeader.FieldNo("IRN Hash"));
                FieldRef.Value := IRN;
                FieldRef := RecRef.Field(SalesInvHeader.FieldNo("Acknowledgement No."));
                FieldRef.Value := FORMAT(BigInt);
                FieldRef := RecRef.Field(SalesInvHeader.FieldNo("Acknowledgement Date"));
                FieldRef.Value := AckDate;
                FieldRef := RecRef.Field(SalesInvHeader.FieldNo(IsJSONImported));
                FieldRef.Value := true;
                FieldRef := RecRef.Field(SalesInvHeader.FieldNo("QR Code"));
                TempBlob2.ToRecordRef(RecRef, SalesInvHeader.FieldNo("QR Code"));
                RecRef.Modify();
            end;
            //B2BUPG1.0>>
            /*EInvoiceEntry."IRN No." := IRN;
            //EInvoiceEntry."QR Code" := TempBlob2.Blob;
            TempBlob2.CreateOutStream(OutstreamL);
            //CopyStream(OutstreamL, InstreamL);
            TempBlob2.CreateInStream(InstreamL);
            EInvoiceEntry."QR Code".CreateInStream(InstreamL); 

            EInvoiceEntry."Ack No." := FORMAT(BigInt);
            EInvoiceEntry."Ack Date" := AckDate;
            EInvoiceEntry.MODIFY;*/
            //EInvoiceEntry."QR Code" := TempBlob2.Blob; 
            //TempBlob2.CreateOutStream(OutstreamL);
            //TempBlob2.CreateInStream(InstreamL);
            //EInvoiceEntry."QR Code".CreateInStream(InstreamL);
            RecRef.GetTable(EInvoiceEntry);
            FieldRef := RecRef.Field(EInvoiceEntry.FieldNo("IRN No."));
            FieldRef.Value := IRN;
            FieldRef := RecRef.Field(EInvoiceEntry.FieldNo("Ack No."));
            FieldRef.Value := FORMAT(BigInt);
            FieldRef := RecRef.Field(EInvoiceEntry.FieldNo("Ack Date"));
            FieldRef.Value := AckDate;
            FieldRef := RecRef.Field(EInvoiceEntry.FieldNo("QR Code"));
            TempBlob2.ToRecordRef(RecRef, EInvoiceEntry.FieldNo("QR Code"));
            RecRef.Modify();
            //B2BUPG1.0<<

            EInvoiceLog."Ack No." := EInvoiceEntry."Ack No.";
            EInvoiceLog."Ack Date" := EInvoiceEntry."Ack Date";
        END ELSE
            EInvoiceLog.Status := EInvoiceLog.Status::Failed;
        EInvoiceLog."Date & Time" := CURRENTDATETIME;
        EInvoiceLog."Request/Response Code" := COPYSTR(MessageTxt, 1, MAXSTRLEN(EInvoiceLog."Request/Response Code"));
    End;

    /*  procedure GenerateSignedQrCode(QRText: Text; var TempBlob: Codeunit "Temp Blob");
     var
         QrPart2: Text;
         TempQrText: Text;
         Convert: DotNet SystemConvert;
         MemoryStream: DotNet MemoryStream;
         OStream: OutStream;
         Value: Text;
         i: Integer;
         Mod4: Integer;
         AppendCount: Integer;
         InstreamL: InStream;
         OutstreamL: OutStream;
     begin
         TempQrText := QRText;
         TempQrText := CONVERTSTR(TempQrText, '.', ',');
         QrPart2 := SELECTSTR(2, TempQrText);

         //To check & Resolve base64 Valid length >>
         Mod4 := STRLEN(QrPart2) MOD 4;
         IF Mod4 > 0 THEN BEGIN
             AppendCount := 4 - Mod4;
             FOR i := 1 TO AppendCount DO
                 QrPart2 += '=';
         END;
         //To check & Resolve base64 Valid length <<

         //Part 2 is decoded from base64 >>
         MemoryStream := MemoryStream.MemoryStream(Convert.FromBase64String(QrPart2));
         TempBlob.CREATEOUTSTREAM(OStream);
         MemoryStream.WriteTo(OStream);
         MemoryStream.Close;
         //TempQrText := TempBlob.ReadAsText('', TEXTENCODING::UTF8);
         TempBlob.CreateInStream(InstreamL, TEXTENCODING::UTF8);
         InstreamL.ReadText(TempQrText);
         TempBlob.CreateOutStream(OutstreamL, TEXTENCODING::UTF8);
         CopyStream(OutstreamL, InstreamL);
         OutstreamL.WriteText(TempQrText); //B2BUPG1.0
         //Part 2 is decoded from base64 <<

         CreateQRCode(TempQrText, TempBlob);//Creation of QR code for part 2
     end; */

    local procedure "-----Cancel IRN----------"();
    begin
    end;

    //[TryFunction]
    procedure CancelIRNAdequre(Variant: Variant): Boolean;
    var
        FileManagement: Codeunit 419;
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        EInvoiceRequestAdequre: Codeunit "E-Invoice Request -Adequre";
        EInvoiceLog: Record "E-Invoice Log";
        EInvoiceSetup: Record "E-Invoice Setup";
        GUIDStorage: Text;
        ResponseFileName: Text;
        DocumentNo: Code[20];
        RecRef: RecordRef;
        CancelSalesInvHdr: Record "Sales Invoice Header";
        CancelSalesCrMHdr: Record "Sales Cr.Memo Header";
        CancelTransferShipHdr: Record "Transfer Shipment Header";
        CancelSuccess: Label 'E-Invoice cancelled Successfully.';
        Location: Record Location;
        ResponseLvar: Text;
    begin
        EInvoiceSetup.GET;
        RecRef.GETTABLE(Variant);
        CASE RecRef.NUMBER OF
            112:
                CancelSalesInvHdr := Variant;
            114:
                CancelSalesCrMHdr := Variant;
            5744:
                CancelTransferShipHdr := Variant;//EInvTrans
        END;
        IF GenerateAccessToken() THEN
            IF NOT (EInvoiceRequestAdequre.CancelEInvoice(Variant)) THEN//Generate Json
                EXIT(false);
        EInvoiceLog.RESET;
        IF CancelSalesInvHdr."No." <> '' THEN BEGIN
            EInvoiceLog.SETRANGE("Document Type", EInvoiceLog."Document Type"::Invoice);
            EInvoiceLog.SETRANGE("Document No.", CancelSalesInvHdr."No.");
            Location.GET(CancelSalesInvHdr."Location Code");
        END ELSE
            IF CancelSalesCrMHdr."No." <> '' THEN BEGIN
                EInvoiceLog.SETRANGE("Document Type", EInvoiceLog."Document Type"::"Credit Memo");
                EInvoiceLog.SETRANGE("Document No.", CancelSalesCrMHdr."No.");
                Location.GET(CancelSalesCrMHdr."Location Code");
            END ELSE
                IF CancelTransferShipHdr."No." <> '' THEN BEGIN
                    EInvoiceLog.SETRANGE("Document Type", EInvoiceLog."Document Type"::"Transfer Shipment");
                    EInvoiceLog.SETRANGE("Document No.", CancelTransferShipHdr."No.");
                    Location.GET(CancelTransferShipHdr."Transfer-from Code");
                END;
        EInvoiceLog.FINDLAST;

        ResponseFileName := EInvoiceSetup."JSON Response Path" + DELCHR(EInvoiceLog."Document No.", '=', '/\-_*^@') + '_CancelResponse' + '.Json';
        GUIDStorage := CREATEGUID;

        //E-Invoice API Connection >>
        HttpWebRequest := HttpWebRequest.Create(EInvoiceSetup."Cancel Request URL");
        HttpWebRequest.Method := 'POST';
        HttpWebRequest.Headers.Add('user_name', Location."User Name");
        HttpWebRequest.Headers.Add('password', Location.Password);
        HttpWebRequest.Headers.Add('gstin', Location."GST Registration No.");
        HttpWebRequest.Headers.Add('requestid', GUIDStorage);
        HttpWebRequest.Headers.Add('Authorization', 'bearer ' + EInvoiceSetup."Access Token" + EInvoiceSetup."Access Token 2");
        //E-Invoice API Connection <<

        // //Attaching Body >>
        // FileStream := FileStream.FileStream(EInvoiceLog."Request Path", FileMode.Open);
        // FileStream.CopyTo(HttpWebRequest.GetRequestStream);
        // // Attaching Body <<

        HttpWebResponse := HttpWebRequest.GetResponse();

        InStr := HttpWebResponse.GetResponseStream;

        CLEAR(TempBlob);
        TempBlob.CREATEOUTSTREAM(OutStr);
        COPYSTREAM(OutStr, InStr);
        //TempBlob.EXPORT(ResponseFileName);
        //FileManagement.BLOBExport(TempBlob, ResponseFileName, true);
        FileManagement.BLOBExportToServerFile(TempBlob, ResponseFileName);

        // Read Json and Update Posted Document response
        ReadCancelResponseJSON(ResponseLvar, EInvoiceLog);

        EInvoiceLog."Request GUID" := GUIDStorage;
        EInvoiceLog."Response Path" := ResponseFileName;
        EInvoiceLog."User Id" := USERID;
        EInvoiceLog.MODIFY;
        if not BatchPosting then
            IF EInvoiceLog.Status = EInvoiceLog.Status::Failed THEN begin
                MESSAGE(EInvFailTxt, FORMAT(EInvoiceLog."Document Type"), EInvoiceLog."Request/Response Code");
                exit(false);
            end ELSE begin
                MESSAGE(CancelSuccess);
                exit(true);
            end;
    end;

    procedure ReadCancelResponseJSON(ResponseL: Text; var EInvoiceLog: Record "E-Invoice Log")
    var
        JSONOBJL: JsonObject;
        JSTokenSu: JsonToken;
        JSTokenMes: JsonToken;
        JSTokenRes: JsonToken;
        SuccessL: Boolean;
        JSTokencanDt: JsonToken;
        JSIRN: JsonToken;
        JSTokenSign: JsonToken;
        SuccessTxt: Text;
        MessageTxt: Text;
        Success: Boolean;
        JsonText: Text;
        ResponseValue: Variant;
        IRN: Text[100];
        CancelDate: DateTime;
        JSONOBJ2: JsonObject;
        JSTOken2: JsonToken;
        ResultL: Text;
        OutS: OutStream;
        CancelDateT: Text;
    begin
        //JsonText := TempBlob.ReadAsText('', TEXTENCODING::UTF8);
        /*  TempBlob.CreateInStream(InstreamL, TEXTENCODING::UTF8);
         InstreamL.ReadText(JsonText);
         TempBlob.CreateOutStream(OutstreamL, TEXTENCODING::UTF8);
         CopyStream(OutstreamL, InstreamL);
         OutstreamL.WriteText(JsonText); //B2BUPG1.0 */

        JSONOBJL := ReadJson(ResponseL);

        JSONOBJL.Get('success', JSTokenSu);
        SuccessTxt := JSTokenSu.AsValue().AsText();
        Success := JSTokenSu.AsValue().AsBoolean();

        JSONOBJL.Get('message', JSTokenMes);
        MessageTxt := JSTokenMes.AsValue().AsText();

        CASE EInvoiceLog."Document Type" OF
            EInvoiceLog."Document Type"::Invoice:
                EInvoiceEntry.GET(EInvoiceEntry."Document Type"::"Sales Invoice", EInvoiceLog."Document No.");
            EInvoiceLog."Document Type"::"Credit Memo":
                EInvoiceEntry.GET(EInvoiceEntry."Document Type"::"Sales Cr. Memo", EInvoiceLog."Document No.");
            EInvoiceLog."Document Type"::"Transfer Shipment":
                EInvoiceEntry.GET(EInvoiceEntry."Document Type"::"Transfer Shipment", EInvoiceLog."Document No.");
        END;

        IF Success THEN BEGIN
            JSONOBJL.Get('result', JSTokenRes);
            if JSTokenRes.IsObject() then begin
                JSTokenRes.WriteTo(ResultL);
                JSONOBJ2.ReadFrom(ResultL);
                JSONOBJL.Get('result', JSTokenRes);

                JSONOBJ2.Get('Irn', JSIRN);
                IRN := JSIRN.AsValue().AsText();

                JSONOBJ2.Get('CancelDate', JSTokencanDt);
                CancelDateT := JSTokencanDt.AsValue().AsText();
                CancelDate := GetDateTimeFromText(CancelDateT);
            END;
            EInvoiceEntry."IRN No." := IRN;
            EInvoiceEntry."IRN Cancelled" := TRUE;
            EInvoiceEntry."IRN Cancelled Date" := CancelDate;
            EInvoiceEntry."IRN Cancelled By" := USERID;
            EInvoiceEntry.MODIFY;
        END ELSE BEGIN
            EInvoiceLog.Status := EInvoiceLog.Status::Failed;

            EInvoiceEntry."IRN Cancelled Reason" := '';
            EInvoiceEntry."IRN Cancelled Remarks" := '';
            EInvoiceEntry."IRN Cancelled By" := '';
            EInvoiceEntry.MODIFY;
        END;
        EInvoiceLog."Date & Time" := CURRENTDATETIME;
        EInvoiceLog."Request/Response Code" := COPYSTR(MessageTxt, 1, MAXSTRLEN(EInvoiceLog."Request/Response Code"));
    end;

    local procedure GetDateTimeFromText(DateTimeText: Text): DateTime;
    var
        DateText: Text;
        Day: Integer;
        Month: Integer;
        Year: Integer;
        RetrivedTime: Time;
    begin
        IF DateTimeText = '' THEN
            EXIT;
        DateText := COPYSTR(DateTimeText, 1, 10);
        EVALUATE(Year, COPYSTR(DateText, 1, 4));
        EVALUATE(Month, COPYSTR(DateText, 6, 2));
        EVALUATE(Day, COPYSTR(DateText, 9, 2));
        EVALUATE(RetrivedTime, COPYSTR(DateTimeText, STRLEN(DateText) + 2, STRLEN(DateTimeText) - 3));
        EXIT(CREATEDATETIME(DMY2DATE(Day, Month, Year), RetrivedTime));
    end;

    local procedure "---MasterIndia---"();
    begin
    end;

    local procedure GenerateAccessTokenMI(): Boolean;
    var
        EInvoiceSetup: Record "E-Invoice Setup";
        EInvoiceLog: Record "E-Invoice Log";
        AccessTokenFile: Text;
        AccessTokenCode: Text;
        LocResult: Text[250];
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        FilePath: Text[250];
        FileName: Text[250];
        FileMgt: Codeunit "File Management";
        EInvoiceMiRequest: Codeunit "E-Invoice Request -MI";
        JSONText: Text;
        Jobj: JsonObject;
        Jtoken: JsonToken;
    begin
        EInvoiceSetup.GET;
        IF EInvoiceSetup."MI Access Token" <> '' THEN
            EXIT(TRUE);

        EInvoiceMiRequest.AccessTokenRequest();
        EInvoiceMiRequest.AccessTokenJSON(JSONText);

        HttpContentG.WriteFrom(JSONText);//Attcah Body       
        HttpContentG.GetHeaders(HttpHeadersG);
        HttpHeadersG.Remove('Content-Type');
        HttpHeadersG.Add('Content-Type', 'application/json');
        HttpRequestMessageG.Method := 'POST';
        HttpRequestMessageG.SetRequestUri('https://clientbasic.mastersindia.co/oauth/access_token');
        HttpRequestMessageG.Content(HttpContentG);
        HttpClientG.Send(HttpRequestMessageG, HttpResponseMessageG);
        HttpResponseMessageG.Content().ReadAs(ResponseG);
        Jobj := ReadJSONAcctoken(ResponseG);
        Jobj.Get('access_token', Jtoken);
        AccessTokenCode := Jtoken.AsValue().AsText();
        if not HttpResponseMessageG.IsSuccessStatusCode then
            exit(false);

        //Generate Access Code >>
        // GenerateAccessToken := GenerateAccessToken.GenerateAccesToken();
        //GenerateAccessToken.AccessToken(AccessTokenFile, LocResult, AccessTokenCode);


        FileName := 'MIAccessTokenResponse' + DELCHR(FORMAT(TODAY), '=', '/\_-*^@') + '.Json';//TokenExpiryFix
        FilePath := EInvoiceSetup."MI Access Token Response Path" + FileName;

        if FILE.Exists(FilePath) then
            File.Erase(FilePath);
        TempBlob.CREATEOUTSTREAM(OutStr);
        OutStr.WRITETEXT(AccessTokenFile);
        //TempBlob.EXPORT(FilePath);
        FileMgt.BLOBExportToServerFile(TempBlob, FilePath);
        //FileMgt.BLOBExport(TempBlob, FilePath, true);

        EInvoiceLog.INIT;
        EInvoiceLog."Document Type" := EInvoiceLog."Document Type"::"Access Token";
        EInvoiceLog."Document No." := 'AccessTokenMI';
        EInvoiceLog."Date & Time" := CURRENTDATETIME;
        EInvoiceLog."User Id" := USERID;
        EInvoiceLog."Response Path" := FilePath;
        IF LocResult <> 'Success' THEN
            EInvoiceLog.Status := EInvoiceLog.Status::Failed;
        EInvoiceLog.INSERT(true);

        IF EInvoiceLog.Status = EInvoiceLog.Status::Failed THEN
            EXIT(FALSE);

        EInvoiceSetup."MI Access Token Date" := CURRENTDATETIME;

        IF STRLEN(AccessTokenCode) > MAXSTRLEN(EInvoiceSetup."MI Access Token") THEN BEGIN
            EInvoiceSetup."MI Access Token" := COPYSTR(AccessTokenCode, 1, MAXSTRLEN(EInvoiceSetup."MI Access Token"));
            EInvoiceSetup."MI Access Token 2" :=
              COPYSTR(AccessTokenCode, MAXSTRLEN(EInvoiceSetup."MI Access Token") + 1, MAXSTRLEN(EInvoiceSetup."MI Access Token 2"));
        END ELSE
            EInvoiceSetup."MI Access Token" := AccessTokenCode;
        EInvoiceSetup.MODIFY;

        EXIT(TRUE);
    end;

    //[TryFunction]
    local procedure SalesEInvoiceMI(): Boolean;
    var
        EInvoiceSetup: Record "E-Invoice Setup";
        EInvoiceLog: Record "E-Invoice Log";
        ResponsePath: Text;
        InStr: InStream;
        OutStr: OutStream;
        TempBlob: Codeunit "Temp Blob";
        EInvoiceRequestMI: Codeunit "E-Invoice Request -MI";
        FileMgt: Codeunit "File Management";
        ResponseLvar: Text;
    begin
        EInvoiceSetup.GET;
        IF IsInvoice THEN BEGIN
            // Generating JSON  >>
            EInvoiceRequestMI.SetSalesInvHeader(SalesInvHeader);
            EInvoiceRequestMI.RUN;
            // Generating JSON  <<

            EInvoiceLog.RESET;
            EInvoiceLog.SETRANGE("Document Type", EInvoiceLog."Document Type"::Invoice);
            EInvoiceLog.SETRANGE("Document No.", SalesInvHeader."No.");
            EInvoiceLog.FINDLAST;
            ResponsePath := EInvoiceSetup."MI JSON Response Path" +
                            DELCHR(SalesInvHeader."No." + '_' + FORMAT(CURRENTDATETIME), '=', '/\:*^@') + '_MI_Response' + '.Json';
        END ELSE BEGIN
            // Generating JSON  >>
            EInvoiceRequestMI.SetCrMemoHeader(SalesCrMemoHdr);
            EInvoiceRequestMI.RUN;
            // Generating JSON  <<
            EInvoiceLog.RESET;
            EInvoiceLog.SETRANGE("Document Type", EInvoiceLog."Document Type"::"Credit Memo");
            EInvoiceLog.SETRANGE("Document No.", SalesCrMemoHdr."No.");
            EInvoiceLog.FINDLAST;
            ResponsePath := EInvoiceSetup."MI JSON Response Path" +
                            DELCHR(SalesCrMemoHdr."No." + '_' + FORMAT(CURRENTDATETIME), '=', '/\:*^@') + '_MI_Response' + '.Json';
        END;

        HttpWebRequest := HttpWebRequest.Create(EInvoiceSetup."MI Request URL");
        HttpWebRequest.Method := 'POST';
        HttpWebRequest.ContentType := 'application/json';
        // //Attaching Body >>
        // EInvoiceLog.TESTFIELD("Request Path");
        // FileStream := FileStream.FileStream(EInvoiceLog."Request Path", FileMode.Open);
        // FileStream.CopyTo(HttpWebRequest.GetRequestStream);
        // //Attaching Body <<

        HttpWebResponse := HttpWebRequest.GetResponse();
        ResponseLvar := HttpWebResponse.ToString();
        InStr := HttpWebResponse.GetResponseStream;

        CLEAR(TempBlob);
        TempBlob.CREATEOUTSTREAM(OutStr);
        COPYSTREAM(OutStr, InStr);
        //TempBlob.EXPORT(ResponsePath);
        //FileMgt.BLOBExport(TempBlob, ResponsePath, true);
        FileMgt.BLOBExportToServerFile(TempBlob, ResponsePath);

        IF HttpWebResponse.StatusCode <> 200 THEN
            EXIT(true);

        // Read Json and Update Posted Document response
        ReadResponseMI(ResponseLvar, EInvoiceLog);

        EInvoiceLog."Response Path" := ResponsePath;
        EInvoiceLog.MODIFY;
        if not BatchPosting then
            IF EInvoiceLog.Status = EInvoiceLog.Status::Failed THEN begin
                MESSAGE(EInvFailTxt, FORMAT(EInvoiceLog."Document Type"), EInvoiceLog."Request/Response Code");
                exit(false);
            end ELSE begin
                MESSAGE(SuccessTxt);
                exit(false);
            end;
    end;

    procedure ReadResponseMI(ResponseL: Text; var EInvoiceLog: Record "E-Invoice Log");
    var
        TokenType: Integer;
        ActDate: Date;
        ActTime: Time;
        ActDateText: Text;
        dayValue: Integer;
        monthValue: Integer;
        yearValue: Integer;
        ActTimeText: Text;
        NewValue: Text;
        StatusTxt: Text;
        ResponseValue: Variant;
        JSONText: Text;
        QRText: Text;
        TempBlob2: Codeunit "Temp Blob";
        IRN: Text[100];
        AckNo: Text;
        AckDate: DateTime;
        MessageTxt: Text;
        BigInt: BigInteger;
        InstreamL: InStream;
        OutstreamL: OutStream;
        RecRef: RecordRef;
        FieldRef: FieldRef;
        JSONOBJ2: JsonObject;
        JSTOken2: JsonToken;
        AckDate1: Text;
        JSONOBJ3: JsonObject;
        JSONOBJL: JsonObject;
        JSTokenRes: JsonToken;
        ResultL: Text;
        QrCode: Codeunit "QR Generator";
    begin
        JSONOBJL := ReadJson(ResponseL);

        JSONOBJL.Get('results', JSTokenRes);
        JSTokenRes.WriteTo(ResultL);
        JSONOBJ2.ReadFrom(ResultL);

        if JSONOBJ2.Get('status', JSTokenRes) then
            StatusTxt := JSTokenRes.AsValue().AsText();
        Clear(JSTokenRes);

        IF StatusTxt = 'Success' THEN BEGIN
            JSONOBJ2.Get('message', JSTokenRes);
            if JSTokenRes.IsObject() then begin
                JSTokenRes.WriteTo(ResultL);
                JSONOBJ3.ReadFrom(ResultL);

                JSONOBJ3.Get('AckNo', JSTOken2);
                BigInt := JSTOken2.AsValue().AsBigInteger();
                Clear(JSTOken2);

                JSONOBJ3.Get('AckDt', JSTOken2);
                // Evaluate(AckDate1,format(JSTOken2.AsValue()));
                AckDate1 := JSTOken2.AsValue().AsText();
                Clear(JSTOken2);
                AckDate := GetDateTimeFromText(FORMAT(AckDate1));

                JSONOBJ3.Get('Irn', JSTOken2);
                IRN := JSTOken2.AsValue().AsText();
                Clear(JSTOken2);

                JSONOBJ3.Get('SignedQRCode', JSTOken2);
                QRText := JSTOken2.AsValue().AsText();
                QrCode.GenerateQRCodeImage(QRText, TempBlob2);
            end;
            EInvoiceEntry."QR Code".CreateInStream(InstreamL); //B2BUPG1.0

            EInvoiceEntry."Ack No." := FORMAT(BigInt);
            EInvoiceEntry."Ack Date" := AckDate;
            EInvoiceEntry.MODIFY;
            RecRef.GetTable(EInvoiceEntry);
            FieldRef := RecRef.Field(EInvoiceEntry.FieldNo("IRN No."));
            FieldRef.Value := IRN;
            FieldRef := RecRef.Field(EInvoiceEntry.FieldNo("Ack No."));
            FieldRef.Value := FORMAT(BigInt);
            FieldRef := RecRef.Field(EInvoiceEntry.FieldNo("Ack Date"));
            FieldRef.Value := AckDate;
            FieldRef := RecRef.Field(EInvoiceEntry.FieldNo("QR Code"));
            TempBlob2.ToRecordRef(RecRef, EInvoiceEntry.FieldNo("QR Code"));
            RecRef.Modify();
            //B2BUPG1.0<<

            EInvoiceLog."Ack No." := AckNo;
            EInvoiceLog."Ack Date" := AckDate;
        END ELSE BEGIN
            EInvoiceLog.Status := EInvoiceLog.Status::Failed;

            JSONOBJ2.Get('errorMessage', JSTokenRes);
            MessageTxt := JSTokenRes.AsValue().AsText();
            Clear(JSTokenRes);
        END;
        EInvoiceLog."Date & Time" := CURRENTDATETIME;
        EInvoiceLog."Request/Response Code" := COPYSTR(MessageTxt, 1, MAXSTRLEN(EInvoiceLog."Request/Response Code"));
    end;

    //[TryFunction]
    procedure CancelIrnMI(Variant: Variant): Boolean;
    var
        FileManagement: Codeunit 419;

        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        EInvoiceRequestMI: Codeunit "E-Invoice Request -MI";
        EInvoiceLog: Record "E-Invoice Log";
        EInvoiceSetup: Record "E-Invoice Setup";
        GUIDStorage: Text;
        ResponseFileName: Text;
        DocumentNo: Code[20];
        RecRef: RecordRef;
        CancelSalesInvHdr: Record "Sales Invoice Header";
        CancelSalesCrMHdr: Record "Sales Cr.Memo Header";
        CancelSuccess: Label 'E-Invoice cancelled Successfully.';
        ResponseLvar: text;
    begin
        EInvoiceSetup.GET;
        RecRef.GETTABLE(Variant);
        CASE RecRef.NUMBER OF
            112:
                CancelSalesInvHdr := Variant;
            114:
                CancelSalesCrMHdr := Variant;
        END;

        IF NOT EInvoiceRequestMI.CancelEInvoice(Variant) THEN//Generate Json
            EXIT(false);
        EInvoiceLog.RESET;
        IF CancelSalesInvHdr."No." <> '' THEN BEGIN
            EInvoiceLog.SETRANGE("Document Type", EInvoiceLog."Document Type"::Invoice);
            EInvoiceLog.SETRANGE("Document No.", CancelSalesInvHdr."No.");
        END ELSE BEGIN
            EInvoiceLog.SETRANGE("Document Type", EInvoiceLog."Document Type"::"Credit Memo");
            EInvoiceLog.SETRANGE("Document No.", CancelSalesCrMHdr."No.");
        END;
        EInvoiceLog.FINDLAST;

        ResponseFileName := EInvoiceSetup."MI JSON Response Path" + DELCHR(EInvoiceLog."Document No.", '=', '/\-_*^@') + '_CancelResponseMI' + '.Json';
        GUIDStorage := CREATEGUID;

        //E-Invoice API Connection >>
        HttpWebRequest := HttpWebRequest.Create(EInvoiceSetup."MI Cancel Request URL");
        HttpWebRequest.Method := 'POST';
        HttpWebRequest.ContentType := 'application/json';
        //E-Invoice API Connection <<

        // // Attaching Body >>
        // FileStream := FileStream.FileStream(EInvoiceLog."Request Path", FileMode.Open);
        // FileStream.CopyTo(HttpWebRequest.GetRequestStream);
        // // Attaching Body <<

        HttpWebResponse := HttpWebRequest.GetResponse();
        ResponseLvar := HttpWebResponse.ToString();
        InStr := HttpWebResponse.GetResponseStream;

        if File.Exists(ResponseFileName) then
            File.Erase(ResponseFileName);

        CLEAR(TempBlob);
        TempBlob.CREATEOUTSTREAM(OutStr);
        COPYSTREAM(OutStr, InStr);
        //TempBlob.EXPORT(ResponseFileName);
        //FileManagement.BLOBExport(TempBlob, ResponseFileName, true);
        FileManagement.BLOBExportToServerFile(TempBlob, ResponseFileName);

        // Read Json and Update Posted Document response
        ReadCancelResponseJSON(ResponseLvar, EInvoiceLog);

        EInvoiceLog."Request GUID" := GUIDStorage;
        EInvoiceLog."Response Path" := ResponseFileName;
        EInvoiceLog."User Id" := USERID;
        EInvoiceLog.MODIFY;
        if not BatchPosting then
            IF EInvoiceLog.Status = EInvoiceLog.Status::Failed THEN begin
                MESSAGE(EInvFailTxt, FORMAT(EInvoiceLog."Document Type"), EInvoiceLog."Request/Response Code");
                exit(false);
            end ELSE begin
                MESSAGE(CancelSuccess);
                exit(true);
            end;
    end;

    // local procedure ReadCancelResponseMI(TempBlob: Codeunit "Temp Blob"; var EInvoiceLog: Record "E-Invoice Log");
    // var
    //     JSONTextReader: DotNet JsonTextReader;
    //     //   Jav: DotNet Serialization;
    //    /*  Dir: DotNet GenDictionary;
    //     Dir2: DotNet GenDictionary; */
    //     StatusTxt: Text;
    //     JsonText: Text;
    //     ResponseValue: Variant;
    //     MessageTxt: Text;
    //     IRN: Text[100];
    //     CancelDate: DateTime;
    //     Dir3: DotNet GenDictionary;
    //     InstreamL: InStream;
    //     OutstreamL: OutStream;
    // begin
    //     //JsonText := TempBlob.ReadAsText('', TEXTENCODING::UTF8);
    //     TempBlob.CreateInStream(InstreamL, TEXTENCODING::UTF8);
    //     InstreamL.ReadText(JsonText);
    //     TempBlob.CreateOutStream(OutstreamL, TEXTENCODING::UTF8);
    //     CopyStream(OutstreamL, InstreamL);
    //     OutstreamL.WriteText(JsonText); //B2BUPG1.0


    //     //  Jav := Jav.JavaScriptSerializer;
    //     //Dir := Jav.DeserializeObject(JsonText);

    //     Dir.TryGetValue('results', Dir2);

    //     CLEAR(ResponseValue);
    //     Dir2.TryGetValue('status', ResponseValue);
    //     StatusTxt := FORMAT(ResponseValue);

    //     IF EInvoiceLog."Document Type" = EInvoiceLog."Document Type"::Invoice THEN
    //         EInvoiceEntry.GET(EInvoiceEntry."Document Type"::"Sales Invoice", EInvoiceLog."Document No.")
    //     ELSE
    //         EInvoiceEntry.GET(EInvoiceEntry."Document Type"::"Sales Cr. Memo", EInvoiceLog."Document No.");

    //     IF StatusTxt = 'Success' THEN BEGIN
    //         Dir2.TryGetValue('message', Dir3);
    //         CLEAR(ResponseValue);
    //         Dir3.TryGetValue('Irn', ResponseValue);
    //         IRN := ResponseValue;
    //         CLEAR(ResponseValue);
    //         Dir3.TryGetValue('CancelDate', ResponseValue);
    //         CancelDate := GetDateTimeFromText(FORMAT(ResponseValue));

    //         EInvoiceEntry."IRN No." := IRN;
    //         EInvoiceEntry."IRN Cancelled" := TRUE;
    //         EInvoiceEntry."IRN Cancelled Date" := CancelDate;
    //         EInvoiceEntry."IRN Cancelled By" := USERID;
    //         EInvoiceEntry.MODIFY;
    //     END ELSE BEGIN
    //         EInvoiceLog.Status := EInvoiceLog.Status::Failed;

    //         EInvoiceEntry."IRN Cancelled Reason" := '';
    //         EInvoiceEntry."IRN Cancelled Remarks" := '';
    //         EInvoiceEntry."IRN Cancelled By" := '';
    //         EInvoiceEntry.MODIFY;
    //     END;
    //     EInvoiceLog."Date & Time" := CURRENTDATETIME;
    // end;

    local procedure ReadCancelResponseMI(TempBlob: Codeunit "Temp Blob"; var EInvoiceLog: Record "E-Invoice Log");
    var
        JSONTextReader: DotNet JsonTextReader;
        StatusTxt: Text;
        JsonText: Text;
        ResponseValue: Variant;
        MessageTxt: Text;
        IRN: Text[100];
        CancelDate: DateTime;
        InstreamL: InStream;
        OutstreamL: OutStream;
        JSONOBJL: JsonObject;
        JSTokenSu: JsonToken;
        Success: Boolean;
        JSTokenMes: JsonToken;
        JSTokenRes: JsonToken;
        ResultL: Text;
        JSONOBJ2: JsonObject;
        JSIRN: JsonToken;
        CancelDateT: Text;
        JSTokencanDt: JsonToken;
        JSONOBJ3: JsonObject;
    begin
        //JsonText := TempBlob.ReadAsText('', TEXTENCODING::UTF8);
        TempBlob.CreateInStream(InstreamL, TEXTENCODING::UTF8);
        InstreamL.ReadText(JsonText);
        TempBlob.CreateOutStream(OutstreamL, TEXTENCODING::UTF8);
        CopyStream(OutstreamL, InstreamL);
        OutstreamL.WriteText(JsonText); //B2BUPG1.0


        // JSONOBJL.Get('success', JSTokenSu);
        // Success := JSTokenSu.AsValue().AsBoolean();

        // JSONOBJL.Get('message', JSTokenMes);
        // MessageTxt := JSTokenMes.AsValue().AsText();
        JSONOBJL.Get('results', JSTokenRes);
        JSTokenRes.WriteTo(ResultL);
        JSONOBJ2.ReadFrom(ResultL);
        JSONOBJ2.Get('status', JSTokenRes);
        StatusTxt := JSTokenRes.AsValue().AsText();
        Clear(JSTokenRes);

        IF EInvoiceLog."Document Type" = EInvoiceLog."Document Type"::Invoice THEN
            EInvoiceEntry.GET(EInvoiceEntry."Document Type"::"Sales Invoice", EInvoiceLog."Document No.")
        ELSE
            EInvoiceEntry.GET(EInvoiceEntry."Document Type"::"Sales Cr. Memo", EInvoiceLog."Document No.");

        IF StatusTxt = 'Success' THEN BEGIN
            JSONOBJ2.Get('message', JSTokenRes);
            if JSTokenRes.IsObject() then begin
                JSTokenRes.WriteTo(ResultL);
                JSONOBJ3.ReadFrom(ResultL);

                JSONOBJ3.Get('Irn', JSIRN);
                IRN := JSIRN.AsValue().AsText();

                JSONOBJ3.Get('CancelDate', JSTokencanDt);
                CancelDateT := JSTokencanDt.AsValue().AsText();
                CancelDate := GetDateTimeFromText(CancelDateT);
            END;

            EInvoiceEntry."IRN No." := IRN;
            EInvoiceEntry."IRN Cancelled" := TRUE;
            EInvoiceEntry."IRN Cancelled Date" := CancelDate;
            EInvoiceEntry."IRN Cancelled By" := USERID;
            EInvoiceEntry.MODIFY;
        END ELSE BEGIN
            EInvoiceLog.Status := EInvoiceLog.Status::Failed;

            EInvoiceEntry."IRN Cancelled Reason" := '';
            EInvoiceEntry."IRN Cancelled Remarks" := '';
            EInvoiceEntry."IRN Cancelled By" := '';
            EInvoiceEntry.MODIFY;
        END;
        EInvoiceLog."Date & Time" := CURRENTDATETIME;
    end;
    //B2BESG<<

    local procedure "---Get eInvoice by IRN---"();
    begin
    end;

    procedure TriggerGetEInvoiceByIRNAdequare(): Boolean;
    begin
        IF NOT GenerateAccessToken THEN
            EXIT(FALSE);
        IF NOT GetEInvoiceByIRN THEN
            EXIT(FALSE);
        EXIT(TRUE);
    end;

    //[TryFunction]
    local procedure GetEInvoiceByIRN(): Boolean;
    var
        FileManagement: Codeunit 419;
        /*  FileStream: Dotnet FileStreamDV;
         FileMode: Dotnet FileModeDV; */
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        EInvoiceRequestAdequre: Codeunit "E-Invoice Request -Adequre";
        EInvoiceLog: Record "E-Invoice Log";
        EInvoiceSetup: Record "E-Invoice Setup";
        GUIDStorage: Text;
        ResponseFileName: Text;
        Location: Record Location;
        UserName: Text;
        Password: Text;
        GSTIN: Code[15];
        GetURL: Text[250];
        ResponseLvar: Text;
    begin
        EInvoiceLog.INIT;
        IF IsInvoice THEN BEGIN
            EInvoiceLog."Document Type" := EInvoiceLog."Document Type"::Invoice;
            EInvoiceLog."Document No." := SalesInvHeader."No.";
        END ELSE BEGIN
            EInvoiceLog."Document Type" := EInvoiceLog."Document Type"::"Credit Memo";
            EInvoiceLog."Document No." := SalesCrMemoHdr."No.";
        END;
        EInvoiceLog."User Id" := USERID;
        EInvoiceLog."Date & Time" := CURRENTDATETIME;
        EInvoiceLog.INSERT(true);

        EInvoiceSetup.GET;
        GetURL := EInvoiceSetup."Get IRN URL" + '?irn=' + EInvoiceEntry."IRN No.";

        IF IsInvoice THEN BEGIN
            ResponseFileName := EInvoiceSetup."JSON Response Path" +
                                DELCHR(SalesInvHeader."No." + '_' + FORMAT(CURRENTDATETIME), '=', '/\:-*^@') + '_GetResponse' + '.Json';

            Location.GET(SalesInvHeader."Location Code");
        END ELSE
            IF CreidtMemo THEN BEGIN
                ResponseFileName := EInvoiceSetup."JSON Response Path" +
                                    DELCHR(SalesCrMemoHdr."No." + '_' + FORMAT(CURRENTDATETIME), '=', '/\:-*^@') + '_GetResponse' + '.Json';

                Location.GET(SalesCrMemoHdr."Location Code");
            END ELSE
                IF TransferShipment THEN BEGIN
                    ResponseFileName := EInvoiceSetup."JSON Response Path" +
                                        DELCHR(TransferShipmentHeader."No." + '_' + FORMAT(CURRENTDATETIME), '=', '/\:-*^@') + '_GetResponse' + '.Json';

                    Location.GET(TransferShipmentHeader."Transfer-from Code");
                END;

        Location.TESTFIELD("User Name");
        Location.TESTFIELD(Password);

        UserName := Location."User Name";
        Password := Location.Password;
        GSTIN := Location."GST Registration No.";
        GUIDStorage := CREATEGUID;

        //E-Invoice API Connection >>
        HttpWebRequest := HttpWebRequest.Create(GetURL);
        HttpWebRequest.Method := 'GET';
        HttpWebRequest.ContentType := 'application/json';
        HttpWebRequest.Headers.Add('user_name', UserName);
        HttpWebRequest.Headers.Add('password', Password);
        HttpWebRequest.Headers.Add('gstin', GSTIN);
        HttpWebRequest.Headers.Add('requestid', GUIDStorage);
        HttpWebRequest.Headers.Add('Authorization', 'bearer ' + EInvoiceSetup."Access Token" + EInvoiceSetup."Access Token 2");
        //E-Invoice API Connection <<

        HttpWebResponse := HttpWebRequest.GetResponse();
        ResponseLvar := HttpWebResponse.ToString();
        InStr := HttpWebResponse.GetResponseStream;

        CLEAR(TempBlob);
        TempBlob.CREATEOUTSTREAM(OutStr);
        COPYSTREAM(OutStr, InStr);
        //TempBlob.EXPORT(ResponseFileName);
        //FileManagement.BLOBExport(TempBlob, ResponseFileName, true);
        FileManagement.BLOBExportToServerFile(TempBlob, ResponseFileName);
        IF HttpWebResponse.StatusCode <> 200 THEN
            EXIT(false);

        EInvoiceLog."Request GUID" := GUIDStorage;
        EInvoiceLog."Response Path" := ResponseFileName;
        EInvoiceLog."User Id" := USERID;
        // Read Json and Update Posted Document response
        ReadResponseJSON(ResponseLvar, EInvoiceLog);

        EInvoiceLog.MODIFY;
        if not BatchPosting then
            IF EInvoiceLog.Status = EInvoiceLog.Status::Failed THEN begin
                MESSAGE(GetEInvFailTxt, EInvoiceLog."Request/Response Code");
                exit(false);
            end ELSE begin
                MESSAGE(SuccessTxt);
                exit(true);
            end;
    end;

    local procedure "---E-INVB2C---"();
    begin
    end;

    procedure GenerateQRCodeForB2C(Variant: Variant);
    var
        QRText: Text;
        TempBlob: Codeunit "Temp Blob";
        eInvoiceAdaequare: Codeunit "E-Invoice Request -Adequre";
        StringBuilderLVar: DotNet StringBuilder;
        OutstreamL: OutStream;
        InstreamL: InStream;
        TempText: Text;
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        //>>E-INVB2C >>
        EInvoiceEntry.CALCFIELDS("QR Code");
        IF EInvoiceEntry."QR Code".HASVALUE THEN
            EXIT;
        IF IsInvoice THEN
            eInvoiceAdaequare.SetSalesInvHeader(SalesInvHeader)
        ELSE
            eInvoiceAdaequare.SetCrMemoHeader(SalesCrMemoHdr);

        eInvoiceAdaequare.GenerateFormatForB2C(Variant);

        CLEAR(TempBlob);
        QRText := StringBuilderLVar.ToString;
        // CreateQRCode(QRText, TempBlob);
        //B2BUPG1.0>>
        //EInvoiceEntry."QR Code" := TempBlob.Blob;
        //TempBlob.CreateOutStream(OutstreamL);
        //CopyStream(OutstreamL, InstreamL);
        //TempBlob.CreateInStream(InstreamL);
        //EInvoiceEntry."QR Code".CreateInStream(InstreamL); 
        RecRef.GetTable(EInvoiceEntry);
        TempBlob.ToRecordRef(RecRef, EInvoiceEntry.FieldNo("QR Code"));
        RecRef.Modify();
        //B2BUPG1.0<<
        if not BatchPosting then
            IF EInvoiceEntry."QR Code".HASVALUE THEN BEGIN
                EInvoiceEntry.MODIFY;
                MESSAGE('QR Code Generated');
            END;
        //>>E-INVB2C <<
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterSalesInvHeaderInsert', '', false, false)]
    local procedure OnAfterSalesInvHeaderInsert(var SalesInvHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; WhseShip: Boolean; WhseReceive: Boolean; var TempWhseShptHeader: Record "Warehouse Shipment Header"; var TempWhseRcptHeader: Record "Warehouse Receipt Header")
    var
        EInvoice: Record "E-Invoice Entry";
    begin
        if not EInvoice.Get(EInvoice."Document Type"::"Sales Invoice", SalesInvHeader."No.") then begin
            EInvoice.Init();
            EInvoice."Document No." := SalesInvHeader."No.";
            EInvoice."Document Type" := EInvoice."Document Type"::"Sales Invoice";
            EInvoice.Insert();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterSalesCrMemoHeaderInsert', '', false, false)]
    local procedure OnAfterSalesCrMemoHeaderInsert(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; WhseShip: Boolean; WhseReceive: Boolean; var TempWhseShptHeader: Record "Warehouse Shipment Header"; var TempWhseRcptHeader: Record "Warehouse Receipt Header")
    Var
        EInvoice: Record "E-Invoice Entry";
    begin
        if not EInvoice.Get(EInvoice."Document Type"::"Sales Cr. Memo", SalesCrMemoHeader."No.") then begin
            EInvoice.Init();
            EInvoice."Document No." := SalesCrMemoHeader."No.";
            EInvoice."Document Type" := EInvoice."Document Type"::"Sales Cr. Memo";
            EInvoice.Insert();
        end;
    end;



    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterCheckMandatoryFields', '', false, false)]
    local procedure OnAfterCheckMandatoryFields(var SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    var
        ValidateEInvoiceRequest: Codeunit "Validate E-Invoice Request";
    begin
        //>>E-INV
        IF IsValidDocForEInvoicing(SalesHeader) THEN
            ValidateEInvFields(SalesHeader);

        IF SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" THEN
            ValidateEInvoiceRequest.CheckValidEntriesApplied(SalesHeader);
        //<<E-INV
    end;

    local procedure IsValidDocForEInvoicing(VAR SalesHeader: Record "Sales Header"): Boolean;
    var
        EInvoiceSetup: Record "E-Invoice Setup";
        SalesInvHdr: Record "Sales Invoice Header";
        EInvoiceEntry: Record "E-Invoice Entry";
        ReferenceInvoiceNo: Record "Reference Invoice No.";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        //>>E-INV
        IF (SalesHeader."GST Customer Type" IN [SalesHeader."GST Customer Type"::Unregistered, SalesHeader."GST Customer Type"::" "]) THEN
            EXIT(FALSE);

        IF (SalesHeader."Document Type" IN [SalesHeader."Document Type"::Invoice, SalesHeader."Document Type"::"Credit Memo"]) OR
          SalesHeader.Invoice
        THEN BEGIN
            EInvoiceSetup.GET;
            IF NOT EInvoiceSetup."With Posting" THEN
                EXIT(FALSE);

            IF (SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo") THEN BEGIN
                ReferenceInvoiceNo.SETRANGE("Document Type", ReferenceInvoiceNo."Document Type"::"Credit Memo");
                ReferenceInvoiceNo.SETRANGE("Document No.", SalesHeader."No.");
                ReferenceInvoiceNo.SETRANGE("Source No.", SalesHeader."Bill-to Customer No.");
                ReferenceInvoiceNo.SETRANGE("Source Type", ReferenceInvoiceNo."Source Type"::Customer);
                IF ReferenceInvoiceNo.FINDSET THEN BEGIN
                    REPEAT
                        SalesInvHdr.GET(ReferenceInvoiceNo."Reference Invoice Nos.");
                        //>>Fix 01Oct2020
                        IF SalesInvHdr."Posting Date" >= DMY2DATE(1, 10, 2020) THEN BEGIN
                            EInvoiceEntry.GET(EInvoiceEntry."Document Type"::"Sales Invoice", SalesInvHdr."No.");
                            SalesHeader."EINV Applicable" := NOT EInvoiceEntry."IRN Cancelled";
                        END ELSE
                            SalesHeader."EINV Applicable" := TRUE;
                    //<<Fix 01Oct2020
                    UNTIL (ReferenceInvoiceNo.NEXT = 0) OR (NOT SalesHeader."EINV Applicable");
                    EXIT(SalesHeader."EINV Applicable");
                END ELSE
                    IF (SalesHeader."Applies-to Doc. Type" = SalesHeader."Applies-to Doc. Type"::Invoice) AND
                      (SalesHeader."Applies-to Doc. No." <> '')
                    THEN BEGIN
                        SalesInvHdr.GET(SalesHeader."Applies-to Doc. No.");
                        //>>Fix 01Oct2020
                        IF SalesInvHdr."Posting Date" >= DMY2DATE(1, 10, 2020) THEN BEGIN
                            EInvoiceEntry.GET(EInvoiceEntry."Document Type"::"Sales Invoice", SalesInvHdr."No.");
                            SalesHeader."EINV Applicable" := NOT EInvoiceEntry."IRN Cancelled";
                        END ELSE
                            SalesHeader."EINV Applicable" := TRUE;
                        //<<Fix 01Oct2020
                        EXIT(SalesHeader."EINV Applicable");
                    END ELSE
                        IF (SalesHeader."Applies-to ID" <> '') THEN BEGIN
                            CustLedgEntry.RESET;
                            CustLedgEntry.SETCURRENTKEY("Customer No.", Open);
                            CustLedgEntry.SETRANGE("Customer No.", SalesHeader."Bill-to Customer No.");
                            CustLedgEntry.SETRANGE(Open, TRUE);
                            CustLedgEntry.SETRANGE("Applies-to ID", SalesHeader."Applies-to ID");
                            IF CustLedgEntry.FINDSET THEN
                                REPEAT
                                    IF SalesInvHdr.GET(CustLedgEntry."Document No.") THEN
                                        IF SalesInvHdr."Posting Date" >= DMY2DATE(1, 10, 2020) THEN BEGIN//Fix 01Oct2020
                                            EInvoiceEntry.GET(EInvoiceEntry."Document Type"::"Sales Invoice", SalesInvHdr."No.");
                                            SalesHeader."EINV Applicable" := NOT EInvoiceEntry."IRN Cancelled";
                                        END ELSE
                                            SalesHeader."EINV Applicable" := TRUE;
                                UNTIL (CustLedgEntry.NEXT = 0) OR (NOT SalesHeader."EINV Applicable");
                            EXIT(SalesHeader."EINV Applicable");
                        END;
            END;

            SalesHeader."EINV Applicable" := TRUE;
            EXIT(TRUE);
        END;
        //<<E-INV
    end;

    local procedure ValidateEInvFields(SalesHeader: Record "Sales Header");
    var
        ValidateEInvoiceRequest: Codeunit "Validate E-Invoice Request";
    begin
        //>>E-INV
        IF NOT SalesHeader."EINV Applicable" THEN
            EXIT;
        ValidateEInvoiceRequest.CheckValidations(SalesHeader);
        //<<E-INV
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterFinalizePosting', '', false, false)]
    local procedure OnAfterFinalizePosting(var SalesHeader: Record "Sales Header"; var SalesShipmentHeader: Record "Sales Shipment Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ReturnReceiptHeader: Record "Return Receipt Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    var
        EInvoiceSetup: Record "E-Invoice Setup";
        EInvoiceMgmt: Codeunit "E-Invoice Mgmt.";
    begin
        //>>E-INV
        IF NOT SalesHeader."EINV Applicable" THEN
            EXIT;
        EInvoiceSetup.GET;
        IF (EInvoiceSetup."With Posting") AND (NOT PreviewMode) THEN BEGIN
            IF SalesInvoiceHeader."No." <> '' THEN
                EInvoiceMgmt.SetSalesInvHeader(SalesInvoiceHeader)
            ELSE
                IF SalesCrMemoHeader."No." <> '' THEN
                    EInvoiceMgmt.SetCrMemoHeader(SalesCrMemoHeader);
            EInvoiceMgmt.RUN;
        END;
        //<<E-INV
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Batch Post Mgt.", 'OnBeforeRunBatch', '', false, false)]
    local procedure OnBeforeRunBatch(var SalesHeader: Record "Sales Header"; var ReplacePostingDate: Boolean; PostingDate: Date; ReplaceDocumentDate: Boolean; Ship: Boolean; Invoice: Boolean)
    begin
        BatchPosting := true;
    end;

    local procedure ReadJson(data: Text) result: JsonObject;
    begin
        result.ReadFrom(data);
    end;
}

