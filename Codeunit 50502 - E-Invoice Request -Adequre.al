codeunit 50009 "E-Invoice Request -Adequre"
{
    Permissions = tabledata "E-Invoice Entry" = RMDI, tabledata "E-Invoice Log" = RMDI;
    // version E-INV,5002Fix,FreeSupplyFix,EXPFIX,POSShipToGSTINFix,NonGst,BugFixUnitPrc,E-INVB2C

    // 5002Fix
    // FreeSupplyFix
    // EXPFIX    Only for Invoice
    // NonGst
    // BugFixUnitPrc
    trigger OnRun();
    begin
        //EXPFIX >>
        CLEAR(CurrCode);
        CLEAR(CurrFactor);
        //EXPFIX <<
        IF IsInvoice THEN
            WITH SalesInvoiceHeader DO BEGIN
                IF "GST Customer Type" IN ["GST Customer Type"::Unregistered, "GST Customer Type"::" "]
                THEN
                    ERROR(UnRegCusrErr);

                //EXPFIX >>
                CurrCode := SalesInvoiceHeader."Currency Code";
                CurrFactor := SalesInvoiceHeader."Currency Factor";
                //EXPFIX <<

                DocumentNo := "No.";
                WriteFileHeader;
                WriteTransDtls;
                ReadDocDtls;
                ReadSellerDtls;
                ReadBuyerDtls;
                ReadDispDtls;
                ReadShipDtls;
                ReadItemList;
                ReadPayDtls;
                ReadRefDtls;
                ReadAddlDocDtls;
                ReadExpDtls;
                ReadEwbDtls;
                ReadValDtls;
            END
        ELSE
            IF CreditMemo THEN
                WITH SalesCrMemoHeader DO BEGIN
                    IF "GST Customer Type" IN ["GST Customer Type"::Unregistered, "GST Customer Type"::" "]
                    THEN
                        ERROR(UnRegCusrErr);

                    //EXPFIX >>
                    CurrCode := SalesCrMemoHeader."Currency Code";
                    CurrFactor := SalesCrMemoHeader."Currency Factor";
                    //EXPFIX <<

                    DocumentNo := "No.";
                    WriteFileHeader;
                    WriteTransDtls;
                    ReadDocDtls;
                    ReadSellerDtls;
                    ReadBuyerDtls;
                    ReadDispDtls;
                    ReadShipDtls;
                    ReadItemList;
                    ReadPayDtls;
                    ReadRefDtls;
                    ReadAddlDocDtls;
                    ReadExpDtls;
                    ReadEwbDtls;
                    ReadValDtls;
                END
            //EInvTrans>>
            ELSE
                IF TransferShipment THEN
                    WITH TransferShipmentHeader DO BEGIN
                        //        IF "GST Customer Type" IN ["GST Customer Type"::Unregistered,"GST Customer Type"::" "]
                        //        THEN
                        //          ERROR(UnRegCusrErr);

                        DocumentNo := "No.";
                        WriteFileHeader;
                        WriteTransDtls;
                        ReadDocDtls;
                        ReadSellerDtls;
                        ReadBuyerDtls;
                        ReadDispDtls;
                        ReadShipDtls;
                        ReadItemList;
                        ReadPayDtls;
                        ReadRefDtls;
                        ReadAddlDocDtls;
                        ReadExpDtls;
                        ReadEwbDtls;
                        ReadValDtls;
                    END;
        //EInvTrans<<
        IF DocumentNo <> '' THEN begin
            JObjVerG.WriteTo(JVerTextG);
            ExportAsJson(DocumentNo, JsonRequestPath, JVerTextG);
        end ELSE
            ERROR(RecIsEmptyErr);

        // GST Integration Log Start
        EInvoiceLog.INIT;
        IF IsInvoice THEN BEGIN
            EInvoiceLog."Document Type" := EInvoiceLog."Document Type"::Invoice;
            EInvoiceLog."Document No." := SalesInvoiceHeader."No.";
        END ELSE
            IF CreditMemo THEN BEGIN
                EInvoiceLog."Document Type" := EInvoiceLog."Document Type"::"Credit Memo";
                EInvoiceLog."Document No." := SalesCrMemoHeader."No.";
                //EInvTrans>>
            END ELSE
                IF TransferShipment THEN BEGIN
                    EInvoiceLog."Document Type" := EInvoiceLog."Document Type"::"Transfer Shipment";
                    EInvoiceLog."Document No." := TransferShipmentHeader."No.";
                END;
        //EInvTrans<<
        EInvoiceLog."Request Path" := JsonRequestPath;
        EInvoiceLog.INSERT(true);
        // GST Integration Log End
    end;

    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        //B2BJSONVar>>
        JObjVerG: JsonObject;
        JVerTextG: Text;
        JSODcoDtlsG: JsonObject;
        JSArryDocDtlsG: JsonArray;
        JSOBJValG: JsonObject;
        JObjtrnsG: JsonObject;
        JObjDtlsG: JsonObject;
        JObjSellerDtlsG: JsonObject;
        JObjBuyerDtlsG: JsonObject;
        JObjDispDtlsG: JsonObject;

        JObJCancelG: JsonObject;
        JObjBactchLineG: JsonObject;
        JObjItemArrayG: JsonArray;
        JObjShipDtlsG: JsonObject;
        JObjPayDtlsG: JsonObject;
        JObjRefDtlsG: JsonObject;
        JObjAddlDocDtlsG: JsonObject;
        JObjExpDtlsG: JsonObject;
        JObjEwbDtlsG: JsonObject;
        JObjValDtlsG: JsonObject;
        JVOBJG: JsonValue;
        JObjContrlDtlsG: JsonObject;
        JArryContrlDtlsG: JsonArray;
        JObjPreDtlsG: JsonObject;
        JSArrayPreDtlsG: JsonArray;
        //B2BJSONVar<<
        GlobalNULL: Variant;
        UnRegCusrErr: TextConst ENU = 'E-Invoicing is not applicable for Unregistered Customer.', ENN = 'E-Invoicing is not applicable for Unregistered Customer.';
        RecIsEmptyErr: TextConst ENU = 'Record variable uninitialized.', ENN = 'Record variable uninitialized.';
        IsInvoice: Boolean;
        SalesLinesErr: TextConst Comment = '%1 = Sales Lines count', ENU = 'E-Invoice allowes only 1000 lines per Invoice. Curent transaction is having %1 lines.', ENN = 'E-Invoice allowes only 100 lines per Invoice. Curent transaction is having %1 lines.';
        DocumentNo: Text[20];
        EInvoiceLog: Record "E-Invoice Log";
        JsonRequestPath: Text;
        CurrCode: Code[20];
        CurrFactor: Decimal;
        CreditMemo: Boolean;
        TransferShipment: Boolean;
        TransferShipmentHeader: Record "Transfer Shipment Header";

    local procedure WriteFileHeader();
    begin
        JObjVerG.Add('Version', '1.1');
        JVOBJG.SetValueToNull();
    end;

    local procedure WriteTransDtls();
    var
        SupTyp: Text[10];
        RegRev: Text[1];
        EcmGstin: Code[15];
        Location: Record Location;
    begin
        IF IsInvoice THEN BEGIN
            WITH SalesInvoiceHeader DO
                CASE "GST Customer Type" OF
                    "GST Customer Type"::Registered, "GST Customer Type"::Exempted:
                        SupTyp := 'B2B';
                    "GST Customer Type"::Export:
                        BEGIN
                            IF "GST Without Payment of Duty" THEN
                                SupTyp := 'EXPWOP'
                            ELSE
                                SupTyp := 'EXPWP';
                        END;
                    "GST Customer Type"::"Deemed Export":
                        SupTyp := 'DEXP';
                    "GST Customer Type"::"SEZ Unit", "GST Customer Type"::"SEZ Development":
                        BEGIN
                            IF "GST Without Payment of Duty" THEN
                                SupTyp := 'SEZWOP'
                            ELSE
                                SupTyp := 'SEZWP';
                        END;
                END;
        END ELSE
            IF CreditMemo THEN BEGIN
                WITH SalesCrMemoHeader DO
                    CASE "GST Customer Type" OF
                        "GST Customer Type"::Registered, "GST Customer Type"::Exempted:
                            SupTyp := 'B2B';
                        "GST Customer Type"::Export:
                            BEGIN
                                IF "GST Without Payment of Duty" THEN
                                    SupTyp := 'EXPWOP'
                                ELSE
                                    SupTyp := 'EXPWP';
                            END;
                        "GST Customer Type"::"Deemed Export":
                            SupTyp := 'DEXP';
                        "GST Customer Type"::"SEZ Unit", "GST Customer Type"::"SEZ Development":
                            BEGIN
                                IF "GST Without Payment of Duty" THEN
                                    SupTyp := 'SEZWOP'
                                ELSE
                                    SupTyp := 'SEZWP';
                            END;
                    END;
                //EInvTrans>>
            END ELSE
                IF TransferShipment THEN BEGIN
                    WITH TransferShipmentHeader DO
                        SupTyp := 'B2B'
                END;
        //EInvTrans<<
        //>>v1.03
        RegRev := 'N';
        EcmGstin := '';
        //<<v1.03
        //B2B>>
        JObjtrnsG.Add('TaxSch', 'GST');
        JObjtrnsG.Add('SupTyp', SupTyp);
        JObjtrnsG.Add('RegRev', RegRev);
        IF EcmGstin <> '' THEN
            JObjtrnsG.Add('EcmGstin', EcmGstin)
        else
            JObjtrnsG.Add('EcmGstin', JVOBJG.AsToken());
        JObjtrnsG.Add('IgstOnIntra', 'N');
        JObjVerG.Add('TranDtls', JObjtrnsG);
        //B2B<<

    end;

    local procedure ReadDocDtls();
    var
        Typ: Text[3];
        Dt: Text[10];
    begin
        IF IsInvoice THEN BEGIN
            IF SalesInvoiceHeader."Invoice Type" = SalesInvoiceHeader."Invoice Type"::Taxable THEN
                Typ := 'INV'
            ELSE
                IF (SalesInvoiceHeader."Invoice Type" = SalesInvoiceHeader."Invoice Type"::"Debit Note") OR
                   (SalesInvoiceHeader."Invoice Type" = SalesInvoiceHeader."Invoice Type"::Supplementary)
                THEN
                    Typ := 'DBN'
                ELSE
                    Typ := 'INV';
            Dt := FORMAT(SalesInvoiceHeader."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>');
        END ELSE
            IF CreditMemo THEN BEGIN
                Typ := 'CRN';
                Dt := FORMAT(SalesCrMemoHeader."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>');
                //EInvTrans>>
            END ELSE
                IF TransferShipment THEN BEGIN
                    Typ := 'INV';
                    Dt := FORMAT(TransferShipmentHeader."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>');
                END;
        //EInvTrans<<
        WriteDocDtls(Typ, COPYSTR(DocumentNo, 1, 16), Dt);
    end;

    local procedure WriteDocDtls(Typ: Text[3]; No: Text[16]; Dt: Text[10]);
    begin

        JObjDtlsG.Add('Typ', Typ);
        JObjDtlsG.Add('No', No);
        JObjDtlsG.Add('Dt', Dt);
        JObjVerG.Add('DocDtls', JObjDtlsG);

    end;

    local procedure ReadExpDtls();
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        //GSTManagement: Codeunit 16401;
        ExpCat: Text[3];
        WithPay: Text[1];
        ShipBNo: Text[16];
        ShipBDt: Text[10];
        Port: Text[10];
        RefClm: Text[1];
        InvForCur: Decimal;
        ForCur: Text[3];
        CntCode: Text[2];
    begin
        IF IsInvoice THEN
            WITH SalesInvoiceHeader DO BEGIN
                IF "GST Customer Type" IN
                   ["GST Customer Type"::Export,
                    "GST Customer Type"::"Deemed Export",
                    "GST Customer Type"::"SEZ Unit",
                    "GST Customer Type"::"SEZ Development"]
                THEN BEGIN
                    ShipBNo := COPYSTR("Bill Of Export No.", 1, 16);
                    ShipBDt := FORMAT("Bill Of Export Date", 0, '<Day,2>/<Month,2>/<Year4>');
                    Port := "Exit Point";
                    RefClm := 'N';//
                    ForCur := COPYSTR("Currency Code", 1, 3);
                    CntCode := COPYSTR("Bill-to Country/Region Code", 1, 2);
                END;
            END
        ELSE
            IF CreditMemo THEN
                WITH SalesCrMemoHeader DO BEGIN
                    IF "GST Customer Type" IN
                       ["GST Customer Type"::Export,
                        "GST Customer Type"::"Deemed Export",
                        "GST Customer Type"::"SEZ Unit",
                        "GST Customer Type"::"SEZ Development"]
                    THEN BEGIN
                        ShipBNo := COPYSTR("Bill Of Export No.", 1, 16);
                        ShipBDt := FORMAT("Bill Of Export Date", 0, '<Year4>-<Month,2>-<Day,2>');
                        Port := "Exit Point";
                        RefClm := 'N';//
                        ForCur := COPYSTR("Currency Code", 1, 3);
                        CntCode := COPYSTR("Bill-to Country/Region Code", 1, 2);
                    END;
                END
            //EInvTrans>>
            ELSE
                IF TransferShipment THEN
                    WITH TransferShipmentHeader DO BEGIN
                        ShipBNo := '';
                        ShipBDt := '';
                        Port := '';
                        RefClm := 'N'; ///Need to check
                        ForCur := '';
                        CntCode := '';
                    END;
        //EInvTrans<<
        IF (ShipBNo = '') AND (ShipBDt = '') AND (Port = '') AND (ForCur = '') AND (CntCode = '') THEN BEGIN
            JObjVerG.Add('ExpDtls', JVOBJG.AsToken());
        END ELSE
            WriteExpDtls(ShipBNo, ShipBDt, Port, RefClm, ForCur, CntCode);
    end;

    local procedure WriteExpDtls(ShipBNo: Text[16]; ShipBDt: Text[10]; Port: Text[10]; RefClm: Text[1]; ForCur: Text[3]; CntCode: Text[2]);
    begin
        //B2B>>
        if ShipBNo <> '' then
            JObjExpDtlsG.Add('ShipBNo', ShipBNo)
        else
            JObjExpDtlsG.Add('ShipBNo', JVOBJG.AsToken());
        if ShipBDt <> '' then
            JObjExpDtlsG.Add('ShipBDt', ShipBDt)
        else
            JObjExpDtlsG.Add('ShipBDt', JVOBJG.AsToken());
        if Port <> '' then
            JObjExpDtlsG.Add('Port', Port)
        else
            JObjExpDtlsG.Add('Port', JVOBJG.AsToken());
        if RefClm <> '' then
            JObjExpDtlsG.Add('RefClm', RefClm)
        else
            JObjExpDtlsG.Add('RefClm', JVOBJG.AsToken());
        if ForCur <> '' then
            JObjExpDtlsG.Add('ForCur', ForCur)
        else
            JObjExpDtlsG.Add('ForCur', JVOBJG.AsToken());
        if CntCode <> '' then
            JObjExpDtlsG.Add('CntCode', CntCode)
        else
            JObjExpDtlsG.Add('CntCode', JVOBJG.AsToken());
        JObjVerG.Add('ExpDtls', JObjExpDtlsG);
        //B2B<<
    end;

    local procedure ReadEwbDtls();
    var
        TransId: Text[15];
        TransName: Text[100];
        TransMode: Text[1];
        Distance: Integer;
        TransDocNo: Text[15];
        TransDocDt: Text[10];
        VehNo: Text[20];
        VehType: Text[1];
        TransportMethod: Record 259;
    begin
        IF IsInvoice THEN begin
            WITH SalesInvoiceHeader DO BEGIN
                TransId := '';//Transit/GSTIN
                IF TransportMethod.GET("Transport Method") THEN BEGIN
                    TransName := TransportMethod.Description;
                    CASE TransportMethod."Transportation Mode" OF
                        TransportMethod."Transportation Mode"::Road:
                            TransMode := '1';
                        TransportMethod."Transportation Mode"::Rail:
                            TransMode := '2';
                        TransportMethod."Transportation Mode"::Air:
                            TransMode := '3';
                        TransportMethod."Transportation Mode"::Ship:
                            TransMode := '4';
                    END;
                END;
                Distance := ROUND("Distance (Km)", 1, '=');
                TransDocNo := '';//Trnasport Document No.
                TransDocDt := '';//Transport Doc Date
                VehNo := "Vehicle No.";
                CASE "Vehicle Type" OF
                    "Vehicle Type"::" ":
                        VehType := '';
                    "Vehicle Type"::ODC:
                        VehType := 'O';
                    "Vehicle Type"::Regular:
                        VehType := 'R';
                END;
            END
        end ELSE
            IF CreditMemo THEN begin
                WITH SalesCrMemoHeader DO BEGIN
                    TransId := '';//Transit/GSTIN
                    IF TransportMethod.GET("Transport Method") THEN BEGIN
                        TransName := TransportMethod.Description;
                        CASE TransportMethod."Transportation Mode" OF
                            TransportMethod."Transportation Mode"::Road:
                                TransMode := '1';
                            TransportMethod."Transportation Mode"::Rail:
                                TransMode := '2';
                            TransportMethod."Transportation Mode"::Air:
                                TransMode := '3';
                            TransportMethod."Transportation Mode"::Ship:
                                TransMode := '4';
                        END;
                    END;
                    Distance := ROUND("Distance (Km)", 1, '=');
                    TransDocNo := '';//Trnasport Document No.
                    TransDocDt := '';//Transport Doc Date
                    VehNo := "Vehicle No.";
                    CASE "Vehicle Type" OF
                        "Vehicle Type"::" ":
                            VehType := '';
                        "Vehicle Type"::ODC:
                            VehType := 'O';
                        "Vehicle Type"::Regular:
                            VehType := 'R';
                    END;
                END;
                //EInvTrans>>
            end ELSE
                IF TransferShipment THEN
                    WITH TransferShipmentHeader DO BEGIN
                        TransId := '';//Transit/GSTIN
                        IF TransportMethod.GET("Transport Method") THEN BEGIN
                            TransName := TransportMethod.Description;
                            CASE TransportMethod."Transportation Mode" OF
                                TransportMethod."Transportation Mode"::Road:
                                    TransMode := '1';
                                TransportMethod."Transportation Mode"::Rail:
                                    TransMode := '2';
                                TransportMethod."Transportation Mode"::Air:
                                    TransMode := '3';
                                TransportMethod."Transportation Mode"::Ship:
                                    TransMode := '4';
                            END;
                        END;
                        Distance := ROUND("Distance (Km)", 1, '=');
                        TransDocNo := '';//Trnasport Document No.
                        TransDocDt := '';//Transport Doc Date
                        VehNo := "Vehicle No.";
                        CASE "Vehicle Type" OF
                            "Vehicle Type"::" ":
                                VehType := '';
                            "Vehicle Type"::ODC:
                                VehType := 'O';
                            "Vehicle Type"::Regular:
                                VehType := 'R';
                        END;
                    END;
        //EInvTrans<<

        IF (TransId = '') AND (TransName = '') AND (TransMode = '') AND (Distance = 0) AND (TransDocNo = '') AND (TransDocDt = '') AND
          (VehNo = '') AND (VehType = '')
        THEN BEGIN
            JObjVerG.Add('EwbDtls', JVOBJG.AsToken());
        END ELSE
            WriteEwbDtls(TransId, TransName, TransMode, Distance, TransDocNo, TransDocDt, VehNo, VehType);
    end;

    local procedure WriteEwbDtls(TransId: Text[15]; TransName: Text[100]; TransMode: Text[1]; Distance: Integer; TransDocNo: Text[15]; TransDocDt: Text[10]; VehNo: Text[20]; VehType: Text[1]);
    begin
        //B2B>>
        if TransId <> '' then
            JObjEwbDtlsG.Add('TransId', TransId)
        else
            JObjEwbDtlsG.Add('TransId', JVOBJG.AsToken());
        if TransName <> '' then
            JObjEwbDtlsG.Add('TransName', TransName)
        else
            JObjEwbDtlsG.Add('TransName', JVOBJG.AsToken());
        if TransMode <> '' then
            JObjEwbDtlsG.Add('TransMode', TransMode)
        else
            JObjEwbDtlsG.Add('TransMode', JVOBJG.AsToken());
        JObjEwbDtlsG.Add('Distance', Distance);
        if TransDocNo <> '' then
            JObjEwbDtlsG.Add('TransDocNo', TransDocNo)
        else
            JObjEwbDtlsG.Add('TransDocNo', JVOBJG.AsToken());
        if TransDocDt <> '' then
            JObjEwbDtlsG.Add('TransDocDt', TransDocDt)
        else
            JObjEwbDtlsG.Add('TransDocDt', JVOBJG.AsToken());
        if VehNo <> '' then
            JObjEwbDtlsG.Add('VehNo', VehNo)
        else
            JObjEwbDtlsG.Add('VehNo', JVOBJG.AsToken());
        if VehType <> '' then
            JObjEwbDtlsG.Add('VehType', VehType)
        else
            JObjEwbDtlsG.Add('VehType', JVOBJG.AsToken());
        JObjVerG.Add('EwbDtls', JObjEwbDtlsG);
        //B2B<<
    end;

    local procedure ReadSellerDtls();
    var
        CompanyInformationBuff: Record 79;
        LocationBuff: Record Location;
        StateBuff: Record State;
        Gstin: Text[15];
        LglNm: Text[100];
        TrdNm: Text[100];
        Add1: Text[100];
        Add2: Text[60];
        Loc: Text[60];
        Pin: Text[6];
        Stcd: Code[2];
        Ph: Text[10];
        Em: Text[50];
    begin
        IF IsInvoice THEN
            WITH SalesInvoiceHeader DO BEGIN
                LocationBuff.GET("Location Code");
                //Gstin := LocationBuff."GST Registration No.";//2016CU19
                Gstin := "Location GST Reg. No.";
                CompanyInformationBuff.GET;
                LglNm := CompanyInformationBuff.Name;
                TrdNm := CompanyInformationBuff.Name;
                Add1 := LocationBuff.Address;
                Add2 := LocationBuff."Address 2";
                Loc := LocationBuff.Name;
                Pin := COPYSTR(LocationBuff."Post Code", 1, 6);
                StateBuff.GET(LocationBuff."State Code");
                Stcd := StateBuff."State Code (GST Reg. No.)";//v1.03
                Ph := COPYSTR(LocationBuff."Phone No.", 1, 10);
                Em := GetMailId(LocationBuff."E-Mail");//5002Fix
            END
        ELSE
            IF CreditMemo THEN
                WITH SalesCrMemoHeader DO BEGIN
                    LocationBuff.GET("Location Code");
                    //Gstin := LocationBuff."GST Registration No.";//2016CU19
                    Gstin := "Location GST Reg. No.";
                    CompanyInformationBuff.GET;
                    LglNm := CompanyInformationBuff.Name;
                    TrdNm := CompanyInformationBuff.Name;
                    Add1 := LocationBuff.Address;
                    Add2 := LocationBuff."Address 2";
                    Loc := LocationBuff.Name;
                    Pin := COPYSTR(LocationBuff."Post Code", 1, 6);
                    StateBuff.GET(LocationBuff."State Code");
                    Stcd := StateBuff."State Code (GST Reg. No.)";//v1.03
                    Ph := COPYSTR(LocationBuff."Phone No.", 1, 10);
                    Em := GetMailId(LocationBuff."E-Mail");//5002Fix
                END
            //EInvTrans>>
            ELSE
                IF TransferShipment THEN
                    WITH TransferShipmentHeader DO BEGIN
                        LocationBuff.GET("Transfer-from Code");
                        Gstin := LocationBuff."GST Registration No.";
                        CompanyInformationBuff.GET;
                        LglNm := CompanyInformationBuff.Name;
                        TrdNm := CompanyInformationBuff.Name;
                        Add1 := LocationBuff.Address;
                        Add2 := LocationBuff."Address 2";
                        Loc := LocationBuff.Name;
                        Pin := COPYSTR(LocationBuff."Post Code", 1, 6);
                        StateBuff.GET(LocationBuff."State Code");
                        Stcd := StateBuff."State Code (GST Reg. No.)";//v1.03
                        Ph := COPYSTR(LocationBuff."Phone No.", 1, 10);
                        Em := GetMailId(LocationBuff."E-Mail");//5002Fix
                    END;
        //EInvTrans<<
        WriteSellerDtls(Gstin, LglNm, TrdNm, Add1, Add2, Loc, Pin, Stcd, Ph, Em);
    end;

    local procedure WriteSellerDtls(Gstin: Text[15]; LglNm: Text[100]; TrdNm: Text[100]; Add1: Text[60]; Add2: Text[60]; Loc: Text[60]; Pin: Text[6]; Stcd: Code[2]; Ph: Text[10]; Em: Text[50]);
    var
        PinInt: Integer;
    begin
        //v1.03 parameter change StateNm to Stcd and related code
        //B2B>>
        Evaluate(PinInt, Pin);
        IF Gstin <> '' then
            JObjSellerDtlsG.Add('Gstin', Gstin)
        else
            JObjSellerDtlsG.Add('Gstin', JVOBJG.AsToken());
        IF LglNm <> '' then
            JObjSellerDtlsG.Add('LglNm', LglNm)
        else
            JObjSellerDtlsG.Add('Lglm', JVOBJG.AsToken());
        IF TrdNm <> '' then
            JObjSellerDtlsG.Add('TrdNm', TrdNm)
        else
            JObjSellerDtlsG.Add('TrdNm', JVOBJG.AsToken());
        IF Add1 <> '' then
            JObjSellerDtlsG.Add('Addr1', Add1)
        else
            JObjSellerDtlsG.Add('Addr1', JVOBJG.AsToken());
        IF Add2 <> '' then
            JObjSellerDtlsG.Add('Addr2', Add2)
        else
            JObjSellerDtlsG.Add('Addr2', JVOBJG.AsToken());
        if Loc <> '' then
            JObjSellerDtlsG.Add('Loc', Loc)
        else
            JObjSellerDtlsG.Add('Loc', Loc);
        if Pin <> '' then
            JObjSellerDtlsG.Add('Pin', PinInt)
        else
            JObjSellerDtlsG.Add('Pin', JVOBJG.AsToken());
        If Stcd <> '' then
            JObjSellerDtlsG.Add('Stcd', Stcd)
        else
            JObjSellerDtlsG.Add('Stcd', Stcd);
        if Ph <> '' then
            JObjSellerDtlsG.Add('Ph', Ph)
        else
            JObjSellerDtlsG.Add('Ph', JVOBJG.AsToken());
        if Em <> '' then
            JObjSellerDtlsG.Add('Em', Em)
        else
            JObjSellerDtlsG.Add('Em', JVOBJG.AsToken());
        JObjVerG.Add('SellerDtls', JObjSellerDtlsG);
        //B2B<<

    end;

    local procedure ReadBuyerDtls();
    var
        Contact: Record 5050;
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ShipToAddr: Record "Ship-to Address";
        StateBuff: Record State;
        Gstin: Text[15];
        LglNm: Text[100];
        TrdNm: Text[100];
        Pos: Text[2];
        Addr1: Text[100];
        Addr2: Text[60];
        Loc: Text[60];
        Pin: Text[6];
        Stcd: Code[2];
        Ph: Text[10];
        Em: Text[50];
        Customer: Record Customer;
        LocationBuff: Record 14;
    begin
        //>> POSShipToGSTINFix
        IF IsInvoice THEN
            WITH SalesInvoiceHeader DO BEGIN
                IF "GST Customer Type" = "GST Customer Type"::Export THEN BEGIN
                    Gstin := 'URP';
                    Pin := '999999';
                    Stcd := '96';//v1.03
                    LglNm := "Bill-to Name";
                    TrdNm := "Bill-to Name";
                    Addr1 := "Bill-to Address";
                    Addr2 := "Bill-to Address 2";
                    Loc := "Bill-to City";
                    Pos := '96';
                    IF Contact.GET("Bill-to Contact No.") THEN BEGIN
                        Ph := COPYSTR(Contact."Phone No.", 1, 10);
                        Em := GetMailId(Contact."E-Mail");//5002Fix
                    END;
                END ELSE BEGIN
                    SalesInvoiceLine.SETRANGE("Document No.", "No.");
                    SalesInvoiceLine.SETFILTER("No.", '<>%1', '');//BugFix
                    IF SalesInvoiceLine.FINDFIRST THEN
                        IF (SalesInvoiceLine."GST Place of Supply" = SalesInvoiceLine."GST Place of Supply"::"Ship-to Address") AND
                           (ShipToAddr.GET("Sell-to Customer No.", "Ship-to Code"))
                        THEN BEGIN
                            Gstin := ShipToAddr."GST Registration No.";
                            LglNm := "Ship-to Name";
                            TrdNm := "Ship-to Name";
                            Addr1 := "Ship-to Address";
                            Addr2 := "Ship-to Address 2";
                            Loc := "Ship-to City";
                            StateBuff.GET("GST Ship-to State Code");
                            Pos := StateBuff."State Code (GST Reg. No.)";
                            Stcd := StateBuff."State Code (GST Reg. No.)";
                            Pin := COPYSTR("Ship-to Post Code", 1, 6);
                            Ph := COPYSTR(ShipToAddr."Phone No.", 1, 10);
                            Em := GetMailId(ShipToAddr."E-Mail");//5002Fix
                        END ELSE BEGIN
                            //Customer.GET("Bill-to Customer No.");
                            //Gstin := Customer."GST Registration No.";//2019CU19
                            Gstin := "Customer GST Reg. No.";
                            LglNm := "Bill-to Name";
                            TrdNm := "Bill-to Name";
                            Addr1 := "Bill-to Address";
                            Addr2 := "Bill-to Address 2";
                            Loc := "Bill-to City";
                            //StateBuff.GET(Customer."State Code");
                            StateBuff.GET("GST Bill-to State Code");
                            Stcd := StateBuff."State Code (GST Reg. No.)";
                            Pos := StateBuff."State Code (GST Reg. No.)";
                            Pin := COPYSTR("Bill-to Post Code", 1, 6);
                            IF Contact.GET("Bill-to Contact No.") THEN BEGIN
                                Ph := COPYSTR(Contact."Phone No.", 1, 10);
                                Em := GetMailId(Contact."E-Mail");//5002Fix
                            END;
                        END;
                END;
            END
        ELSE
            IF CreditMemo THEN
                WITH SalesCrMemoHeader DO BEGIN
                    IF "GST Customer Type" = "GST Customer Type"::Export THEN BEGIN
                        Gstin := 'URP';
                        Pin := '999999';
                        Stcd := '96';//v1.03
                        LglNm := "Bill-to Name";
                        TrdNm := "Bill-to Name";
                        Addr1 := "Bill-to Address";
                        Addr2 := "Bill-to Address 2";
                        Loc := "Bill-to City";
                        Pos := '96';
                        IF Contact.GET("Bill-to Contact No.") THEN BEGIN
                            Ph := COPYSTR(Contact."Phone No.", 1, 10);
                            Em := GetMailId(Contact."E-Mail");//5002Fix
                        END;
                    END ELSE BEGIN
                        SalesCrMemoLine.SETRANGE("Document No.", "No.");
                        SalesCrMemoLine.SETFILTER("No.", '<>%1', '');//BugFix
                        IF SalesCrMemoLine.FINDFIRST THEN
                            IF (SalesCrMemoLine."GST Place of Supply" = SalesCrMemoLine."GST Place of Supply"::"Ship-to Address") AND
                               (ShipToAddr.GET("Sell-to Customer No.", "Ship-to Code"))
                            THEN BEGIN
                                Gstin := ShipToAddr."GST Registration No.";
                                LglNm := "Ship-to Name";
                                TrdNm := "Ship-to Name";
                                Addr1 := "Ship-to Address";
                                Addr2 := "Ship-to Address 2";
                                Loc := "Ship-to City";
                                StateBuff.GET("GST Ship-to State Code");
                                Pos := StateBuff."State Code (GST Reg. No.)";
                                Stcd := StateBuff."State Code (GST Reg. No.)";
                                Pin := COPYSTR("Ship-to Post Code", 1, 6);
                                Ph := COPYSTR(ShipToAddr."Phone No.", 1, 10);
                                Em := GetMailId(ShipToAddr."E-Mail");//5002Fix
                            END ELSE BEGIN
                                //Customer.GET("Bill-to Customer No.");
                                //Gstin := Customer."GST Registration No.";//2019CU19
                                Gstin := "Customer GST Reg. No.";
                                LglNm := "Bill-to Name";
                                TrdNm := "Bill-to Name";
                                Addr1 := "Bill-to Address";
                                Addr2 := "Bill-to Address 2";
                                Loc := "Bill-to City";
                                //StateBuff.GET(Customer."State Code");
                                StateBuff.GET("GST Bill-to State Code");
                                Stcd := StateBuff."State Code (GST Reg. No.)";
                                Pos := StateBuff."State Code (GST Reg. No.)";
                                Pin := COPYSTR("Bill-to Post Code", 1, 6);
                                IF Contact.GET("Bill-to Contact No.") THEN BEGIN
                                    Ph := COPYSTR(Contact."Phone No.", 1, 10);
                                    Em := GetMailId(Contact."E-Mail");//5002Fix
                                END;
                            END;
                    END;
                END
            //EInvTrans>>
            ELSE
                IF TransferShipment THEN
                    WITH TransferShipmentHeader DO BEGIN
                        LocationBuff.GET("Transfer-to Code");
                        Gstin := LocationBuff."GST Registration No.";
                        LglNm := "Transfer-to Name";
                        TrdNm := "Transfer-to Name";
                        Addr1 := "Transfer-to Address";
                        Addr2 := "Transfer-to Address 2";
                        Loc := "Transfer-to City";
                        //StateBuff.GET(Customer."State Code");
                        StateBuff.GET(LocationBuff."State Code");
                        Stcd := StateBuff."State Code (GST Reg. No.)";
                        Pos := StateBuff."State Code (GST Reg. No.)";
                        Pin := COPYSTR("Transfer-to Post Code", 1, 6);
                        IF Contact.GET("Transfer-to Contact") THEN BEGIN
                            Ph := COPYSTR(Contact."Phone No.", 1, 10);
                            Em := GetMailId(Contact."E-Mail");//5002Fix
                        END;
                    END;
        //EInvTrans<<
        //<< POSShipToGSTINFix
        WriteBuyerDtls(Gstin, LglNm, TrdNm, Pos, Addr1, Addr2, Loc, Pin, Stcd, Ph, Em);
    end;

    local procedure WriteBuyerDtls(Gstin: Text[15]; LglNm: Text[100]; TrdNm: Text[100]; Pos: Text[2]; Addr1: Text[100]; Addr2: Text[60]; Loc: Text[60]; Pin: Text[6]; Stcd: Code[2]; Ph: Text[10]; Em: Text[50]);
    var
        PinInt: Integer;
    begin
        //v1.03 //Parameter changed from State to Stcd and related code

        //B2B>>
        Evaluate(PinInt, Pin);
        IF Gstin <> '' then
            JObjBuyerDtlsG.Add('Gstin', Gstin)
        else
            JObjBuyerDtlsG.Add('Gstin', JVOBJG.AsToken());
        IF LglNm <> '' then
            JObjBuyerDtlsG.Add('LglNm', LglNm)
        else
            JObjBuyerDtlsG.Add('Lglm', JVOBJG.AsToken());
        IF TrdNm <> '' then
            JObjBuyerDtlsG.Add('TrdNm', TrdNm)
        else
            JObjBuyerDtlsG.Add('TrdNm', JVOBJG.AsToken());
        if Pos <> '' then
            JObjBuyerDtlsG.Add('Pos', Pos)
        else
            JObjBuyerDtlsG.Add('Pos', JVOBJG.AsToken());
        IF Addr1 <> '' then
            JObjBuyerDtlsG.Add('Addr1', Addr1)
        else
            JObjBuyerDtlsG.Add('Addr1', JVOBJG.AsToken());
        IF Addr2 <> '' then
            JObjBuyerDtlsG.Add('Addr2', Addr2)
        else
            JObjBuyerDtlsG.Add('Addr2', JVOBJG.AsToken());
        if Loc <> '' then
            JObjBuyerDtlsG.Add('Loc', Loc)
        else
            JObjBuyerDtlsG.Add('Loc', JVOBJG.AsToken());
        if Pin <> '' then
            JObjBuyerDtlsG.Add('Pin', PinInt)
        else
            JObjBuyerDtlsG.Add('Pin', JVOBJG.AsToken());
        If Stcd <> '' then
            JObjBuyerDtlsG.Add('Stcd', Stcd)
        else
            JObjBuyerDtlsG.Add('Stcd', JVOBJG.AsToken());
        if Ph <> '' then
            JObjBuyerDtlsG.Add('Ph', Ph)
        else
            JObjBuyerDtlsG.Add('Ph', JVOBJG.AsToken());
        if Em <> '' then
            JObjBuyerDtlsG.Add('Em', Em)
        else
            JObjBuyerDtlsG.Add('Em', JVOBJG.AsToken());
        JObjVerG.Add('BuyerDtls', JObjBuyerDtlsG);
        //B2B<<
    end;

    local procedure ReadDispDtls();
    var
        CompanyInformationBuff: Record 79;
        LocationBuff: Record Location;
        StateBuff: Record State;
        Nm: Text[100];
        Add1: Text[100];
        Add2: Text[60];
        Loc: Text[60];
        Pin: Text[6];
        Stcd: Text[2];
    begin
        IF IsInvoice THEN
            WITH SalesInvoiceHeader DO BEGIN
                CompanyInformationBuff.GET;
                Nm := CompanyInformationBuff.Name;
                LocationBuff.GET("Location Code");
                Add1 := LocationBuff.Address;
                Add2 := LocationBuff."Address 2";
                Loc := LocationBuff.Name;
                Pin := COPYSTR(LocationBuff."Post Code", 1, 6);
                StateBuff.GET(LocationBuff."State Code");
                Stcd := StateBuff."State Code (GST Reg. No.)";
            END
        ELSE
            IF CreditMemo THEN
                WITH SalesCrMemoHeader DO BEGIN
                    /*CompanyInformationBuff.GET;
                    Nm := "Sell-to Customer Name";
                    LocationBuff.GET("Location Code");
                    Add1 := "Sell-to Address";
                    Add2 := "Sell-to Address 2";
                    Loc := "Sell-to City";
                    Pin := COPYSTR("Sell-to Post Code", 1, 6);
                    if State = '' then
                        StateBuff.GET("GST Bill-to State Code")
                    else
                        StateBuff.GET(State);
                    Stcd := StateBuff."State Code (GST Reg. No.)";*/
                    JObjVerG.Add('DispDtls', JVOBJG.AsToken());
                END
            //EInvTrans>>
            ELSE
                IF TransferShipment THEN BEGIN
                    /*WITH TransferShipmentHeader DO BEGIN
                      CompanyInformationBuff.GET;
                      Nm := CompanyInformationBuff.Name;
                      LocationBuff.GET("Transfer-from Code");
                      Add1 := LocationBuff.Address;
                      Add2 := LocationBuff."Address 2";
                      Loc := LocationBuff.Name;
                      Pin := COPYSTR(LocationBuff."Post Code",1,6);
                      StateBuff.GET(LocationBuff."State Code");
                      Stcd := StateBuff."State Code (GST Reg. No.)";
                      END;*/
                    JObjVerG.Add('DispDtls', JVOBJG.AsToken());

                END;
        //EInvTrans<<
        IF IsInvoice THEN
            WriteDispDtls(Nm, Add1, Add2, Loc, Pin, Stcd);

        //WriteDispDtls(Nm, Add1, Add2, Loc, Pin, Stcd);
    end;

    local procedure WriteDispDtls(Nm: Text[100]; Add1: Text[100]; Add2: Text[60]; Loc: Text[60]; Pin: Text[6]; Stcd: Text[2]);
    var
        PinInt: Integer;
    begin
        EVALUATE(PinInt, Pin);
        if Nm <> '' then
            JObjDispDtlsG.Add('Nm', Nm)
        else
            JObjDispDtlsG.Add('Nm', JVOBJG.AsToken());
        if Add1 <> '' then
            JObjDispDtlsG.Add('Addr1', Add1)
        else
            JObjDispDtlsG.Add('Addr1', JVOBJG.AsToken());
        if Add2 <> '' then
            JObjDispDtlsG.Add('Addr2', Add2)
        else
            JObjDispDtlsG.Add('Addr2', JVOBJG.AsToken());
        if Loc <> '' then
            JObjDispDtlsG.Add('Loc', Loc)
        else
            JObjDispDtlsG.Add('Loc', JVOBJG.AsToken());
        if Pin <> '' then
            JObjDispDtlsG.Add('Pin', PinInt)
        else
            JObjDispDtlsG.Add('Pin', JVOBJG.AsToken());
        if Stcd <> '' then
            JObjDispDtlsG.Add('Stcd', Stcd)
        else
            JObjDispDtlsG.Add('Stcd', JVOBJG.AsToken());
        JObjVerG.Add('DispDtls', JObjDispDtlsG);
    end;

    local procedure ReadShipDtls();
    var
        ShipToAddr: Record "Ship-to Address";
        StateBuff: Record State;
        Gstin: Text[15];
        LglNm: Text[100];
        TrdNm: Text[100];
        Addr1: Text[100];
        Addr2: Text[60];
        Loc: Text[60];
        Pin: Text[6];
        Stcd: Text[2];
        Ph: Text[10];
        Em: Text[50];
        Customer: Record Customer;
        LocationBuff: Record Location;
        CompanyInformationBuff: Record "Company Information";
    begin
        IF IsInvoice THEN BEGIN
            WITH SalesInvoiceHeader DO BEGIN
                IF ShipToAddr.GET("Sell-to Customer No.", "Ship-to Code") THEN BEGIN
                    LglNm := "Ship-to Name";
                    TrdNm := "Ship-to Name";
                    Addr1 := "Ship-to Address";
                    Addr2 := "Ship-to Address 2";
                    Loc := "Ship-to City";
                    //v1.03  >>
                    IF "GST Customer Type" <> "GST Customer Type"::Export THEN BEGIN
                        Gstin := ShipToAddr."GST Registration No.";
                        StateBuff.GET("GST Ship-to State Code");
                        //StateBuff.GET(ShipToAddr.State);
                        Stcd := StateBuff."State Code (GST Reg. No.)";
                        Pin := COPYSTR("Ship-to Post Code", 1, 6);
                    END ELSE BEGIN
                        Gstin := '';
                        Stcd := '97';//v1.03 //Other Territory
                        Pin := '999999';
                    END;
                    //v1.03 <<
                END ELSE BEGIN
                    LglNm := "Bill-to Name";
                    TrdNm := "Bill-to Name";
                    Addr1 := "Bill-to Address";
                    Addr2 := "Bill-to Address 2";
                    Loc := "Bill-to City";

                    IF "GST Customer Type" <> "GST Customer Type"::Export THEN BEGIN
                        /*
                        Customer.GET("Bill-to Customer No.");
                        Gstin := Customer."GST Registration No.";
                        *///2019CU19
                        Gstin := "Customer GST Reg. No.";
                        //>>v1.03
                        StateBuff.GET("GST Bill-to State Code");
                        //StateBuff.GET(Customer."State Code");
                        //<<v1.03
                        Stcd := StateBuff."State Code (GST Reg. No.)";
                        Pin := COPYSTR("Bill-to Post Code", 1, 6);
                    END ELSE BEGIN
                        Gstin := '';
                        Stcd := '97';//v1.03 //Other Territory
                        Pin := '999999';
                    END;
                END;
            END;
            WriteShipDtls(Gstin, LglNm, TrdNm, Addr1, Addr2, Loc, Pin, Stcd);
        END ELSE
            IF CreditMemo THEN BEGIN
                WITH SalesCrMemoHeader DO BEGIN
                    /*IF ShipToAddr.GET("Sell-to Customer No.", "Ship-to Code") THEN BEGIN
                        LglNm := "Ship-to Name";
                        TrdNm := "Ship-to Name";
                        Addr1 := "Ship-to Address";
                        Addr2 := "Ship-to Address 2";
                        Loc := "Ship-to City";
                        //v1.03  >>
                        IF "GST Customer Type" <> "GST Customer Type"::Export THEN BEGIN
                            Gstin := ShipToAddr."GST Registration No.";
                            StateBuff.GET("GST Ship-to State Code");
                            //StateBuff.GET(ShipToAddr.State);
                            Stcd := StateBuff."State Code (GST Reg. No.)";
                            Pin := COPYSTR("Ship-to Post Code", 1, 6);
                        END ELSE BEGIN
                            Gstin := '';
                            Stcd := '97';//v1.03 //Other Territory
                            Pin := '999999';
                        END;
                        //v1.03 <<
                    END ELSE BEGIN
                        LglNm := "Bill-to Name";
                        TrdNm := "Bill-to Name";
                        Addr1 := "Bill-to Address";
                        Addr2 := "Bill-to Address 2";
                        Loc := "Bill-to City";

                        IF "GST Customer Type" <> "GST Customer Type"::Export THEN BEGIN
                            Gstin := "Location GST Reg. No.";
                            StateBuff.GET("Location State Code");
                            //StateBuff.GET(Customer."State Code");
                            Stcd := StateBuff."State Code (GST Reg. No.)";
                            Pin := COPYSTR("Bill-to Post Code", 1, 6);
                        END ELSE BEGIN
                            Gstin := '';
                            Stcd := '97';//v1.03 //Other Territory
                            Pin := '999999';
                        END;
                    END;*/
                    IF "GST Customer Type" <> "GST Customer Type"::Export THEN BEGIN
                        Gstin := "Location GST Reg. No.";
                        StateBuff.GET("Location State Code");
                        //StateBuff.GET(Customer."State Code");
                        Stcd := StateBuff."State Code (GST Reg. No.)";
                        Pin := COPYSTR("Bill-to Post Code", 1, 6);
                    END ELSE BEGIN
                        Gstin := '';
                        Stcd := '97';//v1.03 //Other Territory
                        Pin := '999999';
                    END;
                    CompanyInformationBuff.GET;
                    LglNm := CompanyInformationBuff.Name;
                    TrdNm := CompanyInformationBuff.Name;
                    LocationBuff.GET("Location Code");
                    Addr1 := LocationBuff.Address;
                    Addr2 := LocationBuff."Address 2";
                    Loc := LocationBuff.City;
                    Pin := COPYSTR(LocationBuff."Post Code", 1, 6);
                    StateBuff.GET(LocationBuff."State Code");
                    Stcd := StateBuff."State Code (GST Reg. No.)";
                END;
                WriteShipDtls(Gstin, LglNm, TrdNm, Addr1, Addr2, Loc, Pin, Stcd);
                //EInvTrans>>
            END ELSE
                IF TransferShipment THEN BEGIN
                    /*WITH TransferShipmentHeader DO BEGIN
                        LocationBuff.GET("Transfer-to Code");
                        LglNm := "Transfer-to Name";
                        TrdNm := "Transfer-to Name";
                        Addr1 := "Transfer-to Address";
                        Addr2 := "Transfer-to Address 2";
                        Loc := "Transfer-to City";
                        //v1.03  >>
                          Gstin := LocationBuff."GST Registration No.";
                          StateBuff.GET(LocationBuff."State Code");
                          //StateBuff.GET(ShipToAddr.State);
                          Stcd := StateBuff."State Code (GST Reg. No.)";
                          Pin := COPYSTR("Transfer-to Post Code",1,6);
                          END;*/
                    //JsonTextWriter.WritePropertyName('ShipDtls');
                    //JsonTextWriter.WriteValue(GlobalNULL);
                    WriteShipDtls(Gstin, LglNm, TrdNm, Addr1, Addr2, Loc, Pin, Stcd);
                END;
        //EInvTrans<<

    end;

    local procedure WriteShipDtls(Gstin: Text[15]; LglNm: Text[100]; TrdNm: Text[100]; Addr1: Text[60]; Addr2: Text[60]; Loc: Text[60]; Pin: Text[6]; Stcd: Text[2]);
    var
        PinInt: Integer;
    begin
        //B2BSaas>>
        Evaluate(PinInt, Pin);
        IF Gstin <> '' then
            JObjShipDtlsG.Add('Gstin', Gstin)
        else
            JObjShipDtlsG.Add('Gstin', JVOBJG.AsToken());
        IF LglNm <> '' then
            JObjShipDtlsG.Add('LglNm', LglNm)
        else
            JObjShipDtlsG.Add('Lglm', JVOBJG.AsToken());
        IF TrdNm <> '' then
            JObjShipDtlsG.Add('TrdNm', TrdNm)
        else
            JObjShipDtlsG.Add('TrdNm', JVOBJG.AsToken());
        IF Addr1 <> '' then
            JObjShipDtlsG.Add('Addr1', Addr1)
        else
            JObjShipDtlsG.Add('Addr1', JVOBJG.AsToken());
        IF Addr2 <> '' then
            JObjShipDtlsG.Add('Addr2', Addr2)
        else
            JObjShipDtlsG.Add('Addr2', JVOBJG.AsToken());
        if Loc <> '' then
            JObjShipDtlsG.Add('Loc', Loc)
        else
            JObjShipDtlsG.Add('Loc', JVOBJG.AsToken());
        if Pin <> '' then
            JObjShipDtlsG.Add('Pin', PinInt)
        else
            JObjShipDtlsG.Add('Pin', JVOBJG.AsToken());
        If Stcd <> '' then
            JObjShipDtlsG.Add('Stcd', Stcd)
        else
            JObjShipDtlsG.Add('Stcd', JVOBJG.AsToken());
        JObjVerG.Add('ShipDtls', JObjShipDtlsG);
        //B2BSaas<<
    end;

    local procedure ReadItemList();
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SlNo: Integer;
        TransferShipmentLine: Record "Transfer Shipment Line";
        NumberFilter: Text;
    begin
        NumberFilter := '<>''''';
        IF GetInvRoundingAcc <> '' THEN
            NumberFilter += '&<>' + GetInvRoundingAcc;
        IF GetNumberFilter <> '' THEN
            NumberFilter += '&<>' + GetNumberFilter;
        IF IsInvoice THEN BEGIN
            SalesInvoiceLine.SETRANGE("Document No.", DocumentNo);
            //B2BUPG1.0>>
            //SalesInvoiceLine.SETFILTER("No.", '<>%1&<>%2&<>%3', '', GetInvRoundingAcc, GetGSTRoundingAcc);
            SalesInvoiceLine.SETFILTER("No.", NumberFilter);
            //B2BUPG1.0<<
            SalesInvoiceLine.SETFILTER(Quantity, '<>%1', 0);
            IF SalesInvoiceLine.FINDSET THEN BEGIN
                IF SalesInvoiceLine.COUNT > 1000 THEN
                    ERROR(SalesLinesErr, SalesInvoiceLine.COUNT);

                repeat
                    SlNo += 1;
                    //B2BSaas>>
                    WriteItem(SalesInvoiceLine, SlNo);
                until SalesInvoiceLine.Next() = 0;
                JObjVerG.Add('ItemList', JObjItemArrayG);
                //B2BSaas<<
            end;
        END ELSE
            IF CreditMemo THEN BEGIN
                SalesCrMemoLine.SETRANGE("Document No.", DocumentNo);
                //B2BUPG1.0>>
                //SalesCrMemoLine.SETFILTER("No.", '<>%1&<>%2&<>%3', '', GetInvRoundingAcc, GetGSTRoundingAcc);
                SalesCrMemoLine.SETFILTER("No.", NumberFilter);
                //B2BUPG1.0<<
                SalesCrMemoLine.SETFILTER(Quantity, '<>%1', 0);
                IF SalesCrMemoLine.FINDSET THEN BEGIN
                    IF SalesCrMemoLine.COUNT > 1000 THEN
                        ERROR(SalesLinesErr, SalesCrMemoLine.COUNT);
                    repeat
                        SlNo += 1;
                        //B2B>>
                        WriteItem(SalesCrMemoLine, SlNo);
                    until SalesCrMemoLine.Next() = 0;
                    JObjVerG.Add('ItemList', JObjItemArrayG);
                    //B2B<<
                END;
                //EInvTrans>>
            END ELSE
                IF TransferShipment THEN BEGIN
                    TransferShipmentLine.SETRANGE("Document No.", DocumentNo);
                    TransferShipmentLine.SETFILTER("Item No.", '<>%1', '');
                    TransferShipmentLine.SETFILTER(Quantity, '<>%1', 0);
                    IF TransferShipmentLine.FINDSET THEN BEGIN
                        IF TransferShipmentLine.COUNT > 1000 THEN
                            ERROR(SalesLinesErr, TransferShipmentLine.COUNT);
                        repeat
                            SlNo += 1;
                            //B2BSaas>>
                            WriteItem(TransferShipmentLine, SlNo);
                        until TransferShipmentLine.Next() = 0;
                        JObjVerG.Add('ItemList', JObjItemArrayG);
                        //B2BSaas<<
                    END;
                END;
        //EInvTrans>>
    end;

    local procedure WriteItem(Variant: Variant; SlNo: Integer);
    var
        RecRef: RecordRef;
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ValueEntry: Record 5802;
        ItemLedgerEntry: Record 32;
        ValueEntryRelation: Record 6508;
        ItemTrackingManagement: Codeunit 6500;
        InvoiceRowID: Text[250];
        IsServc: Text[1];
        PrdDesc: Text[100];
        HsnCd: Text[8];
        Qty: Decimal;
        Unit: Text[3];
        UnitPrice: Decimal;
        TotAmt: Decimal;
        Discount: Decimal;
        AssAmt: Decimal;
        GstRt: Decimal;
        CgstAmt: Decimal;
        SgstAmt: Decimal;
        IgstAmt: Decimal;
        CesRt: Decimal;
        CesAmt: Decimal;
        CesNonAdvlAmt: Decimal;
        StateCesRt: Decimal;
        StateCesAmt: Decimal;
        StateCesNonAdvlAmt: Decimal;
        OthChrg: Decimal;
        TotItemVal: Decimal;
        Item: Record 27;
        LotExist: Boolean;
        LineNo: Integer;
        Barcde: Text[30];
        FreeQty: Decimal;
        PreTaxVal: Decimal;
        OrdLineRef: Integer;
        OrgCntry: Code[2];
        PrdSlNo: Code[20];
        UOM: Record "Unit of Measure";
        CurrExchRate: Record 330;
        TotGSTAmt: Decimal;
        TransferShipmentLine: Record "Transfer Shipment Line";
        JObjectItems: JsonObject;
        SlNoL: Text;
        OrderLineNolT: Text;
    begin
        RecRef.GETTABLE(Variant);
        CASE RecRef.NUMBER OF
            113:
                SalesInvoiceLine := Variant;
            115:
                SalesCrMemoLine := Variant;
            5745:
                TransferShipmentLine := Variant;//EInvTrans
        END;

        IF IsInvoice THEN BEGIN
            IF SalesInvoiceLine."GST Group Type" = SalesInvoiceLine."GST Group Type"::Service THEN
                IsServc := 'Y'
            ELSE
                IsServc := 'N';
            PrdDesc := SalesInvoiceLine.Description + SalesInvoiceLine."Description 2";
            HsnCd := SalesInvoiceLine."HSN/SAC Code";
            //>>v1.03
            Barcde := '';
            PreTaxVal := ROUND(SalesInvoiceLine.Quantity * SalesInvoiceLine."Unit Price", 0.01, '=');//5002Fix
            OrdLineRef := SalesInvoiceLine."Line No.";
            OrgCntry := 'IN';
            PrdSlNo := '';
            //<<v1.03
            IF SalesInvoiceHeader."Partial Billing" THEN BEGIN
                Qty := ROUND(SalesInvoiceLine."Partial Billing Quantity", 0.001, '=');
                IF Qty <> 0 THEN
                    UnitPrice := PreTaxVal / Qty;
            END ELSE BEGIN
                Qty := ROUND(SalesInvoiceLine.Quantity, 0.001, '='); //BugFixUnitPrc
                UnitPrice := SalesInvoiceLine."Unit Price";
            END;
            //>>FreeSupplyFix
            //B2BUPG1.0>> - commented due to missing of fields.
            /*IF SalesInvoiceLine."Free Supply" THEN BEGIN
                Qty := 0;
                FreeQty := SalesInvoiceLine.Quantity;
                AssAmt := 0;
            END ELSE BEGIN*/
            //B2BUPG1.0<<
            //Qty := ROUND(SalesInvoiceLine.Quantity, 0.001, '='); //BugFixUnitPrc
            FreeQty := 0;
            IF SalesInvoiceLine."GST Assessable Value (LCY)" <> 0 THEN
                AssAmt := SalesInvoiceLine."GST Assessable Value (LCY)"
            //NonGst >>
            ELSE
                //B2BUPG1.0>>
                /*IF SalesInvoiceLine."GST Base Amount" <> 0 THEN
                    AssAmt := SalesInvoiceLine."GST Base Amount"
                ELSE
                    AssAmt := SalesInvoiceLine."Line Amount" + SalesInvoiceLine."Inv. Discount Amount";*/
                    AssAmt := SalesInvoiceLine.Amount;
            //B2BUPG1.0<<
            //NonGst <<
            //END; //B2BUPG1.0
            //<<FreeSupplyFix
            IF UOM.GET(SalesInvoiceLine."Unit of Measure Code") THEN
                Unit := COPYSTR(UOM.Code, 1, 3);
            //UnitPrice := ROUND(SalesInvoiceLine."Unit Price", 0.01, '=');//5002Fix
            TotAmt := SalesInvoiceLine."Line Amount" + SalesInvoiceLine."Line Discount Amount";
            Discount := SalesInvoiceLine."Line Discount Amount" + SalesInvoiceLine."Inv. Discount Amount";//v1.03

            GetGSTCompRate(SalesInvoiceLine."Document No.", SalesInvoiceLine."Line No.",
              GstRt, CgstAmt, SgstAmt, IgstAmt, CesRt, CesAmt, CesNonAdvlAmt, StateCesRt, StateCesAmt, StateCesNonAdvlAmt, TotGSTAmt);
            OthChrg := 0;
            //B2BUPG1.0>>
            //TotItemVal := SalesInvoiceLine."Amount Including Tax" + SalesInvoiceLine."Total GST Amount";
            TotItemVal := SalesInvoiceLine."Line Amount" + TotGSTAmt;
            //B2BUPG1.0

            IF SalesInvoiceLine.Type = SalesInvoiceLine.Type::Item THEN BEGIN
                Item.GET(SalesInvoiceLine."No.");
                LotExist := Item."Item Tracking Code" <> '';
                //>>v1.03
                OrgCntry := 'IN';
                IF Item."Country/Region of Origin Code" <> '' THEN
                    OrgCntry := COPYSTR(Item."Country/Region of Origin Code", 1, 2);
                //<<v1.03
            END;
            LineNo := SalesInvoiceLine."Line No.";
        END ELSE
            IF CreditMemo THEN BEGIN
                IF SalesCrMemoLine."GST Group Type" = SalesCrMemoLine."GST Group Type"::Service THEN
                    IsServc := 'Y'
                ELSE
                    IsServc := 'N';
                PrdDesc := SalesCrMemoLine.Description + SalesCrMemoLine."Description 2";
                HsnCd := SalesCrMemoLine."HSN/SAC Code";
                //>>v1.03
                Barcde := '';
                PreTaxVal := ROUND(SalesCrMemoLine.Quantity * SalesCrMemoLine."Unit Price", 0.01, '=');//5002Fix
                OrdLineRef := SalesCrMemoLine."Line No.";
                OrgCntry := 'IN';
                PrdSlNo := '';
                //<<v1.03
                //>>FreeSupplyFix
                //B2BUPG1.0>> - Comented due to free supply has no solution.
                /*IF SalesCrMemoLine."Free Supply" THEN BEGIN
                    Qty := 0;
                    FreeQty := SalesCrMemoLine.Quantity;
                    AssAmt := 0;
                END ELSE BEGIN*/
                //B2BUPG1.0<<
                Qty := ROUND(SalesCrMemoLine.Quantity, 0.001, '='); //BugFixUnitPrc
                FreeQty := 0;
                IF SalesCrMemoLine."GST Assessable Value (LCY)" <> 0 THEN
                    AssAmt := SalesCrMemoLine."GST Assessable Value (LCY)"
                //NonGst >>
                ELSE
                    //B2BUPG1.0>>
                    /*IF SalesCrMemoLine."GST Base Amount" <> 0 THEN
                        AssAmt := SalesCrMemoLine."GST Base Amount"
                    ELSE
                        AssAmt := SalesCrMemoLine."Line Amount" + SalesCrMemoLine."Line Discount Amount";*/
                    AssAmt := SalesCrMemoLine.Amount;
                //B2BUPG1.0<<
                //NonGst <<
                //END; //B2BUPG1.0
                //<<FreeSupplyFix
                IF UOM.GET(SalesCrMemoLine."Unit of Measure Code") THEN
                    Unit := COPYSTR(UOM.Code, 1, 3);
                UnitPrice := SalesCrMemoLine."Unit Price";
                TotAmt := SalesCrMemoLine."Line Amount" + SalesCrMemoLine."Line Discount Amount";
                Discount := SalesCrMemoLine."Line Discount Amount" + SalesCrMemoLine."Inv. Discount Amount";//v1.03

                GetGSTCompRate(SalesCrMemoLine."Document No.", SalesCrMemoLine."Line No.",
                  GstRt, CgstAmt, SgstAmt, IgstAmt, CesRt, CesAmt, CesNonAdvlAmt, StateCesRt, StateCesAmt, StateCesNonAdvlAmt, TotGSTAmt);
                OthChrg := 0;
                //B2BUPG1.0>>
                //TotItemVal := SalesCrMemoLine."Amount Including Tax" + SalesCrMemoLine."Total GST Amount";
                TotItemVal := SalesCrMemoLine."Line Amount" + TotGSTAmt;
                //B2BUPG1.0<<

                IF SalesCrMemoLine.Type = SalesCrMemoLine.Type::Item THEN BEGIN
                    Item.GET(SalesCrMemoLine."No.");
                    LotExist := Item."Item Tracking Code" <> '';
                    //>>v1.03
                    IF Item."Country/Region of Origin Code" <> '' THEN
                        OrgCntry := COPYSTR(Item."Country/Region of Origin Code", 1, 2);
                    //<<v1.03
                END;
                LineNo := SalesCrMemoLine."Line No.";
                //EInvTrans>>
            END ELSE
                IF TransferShipment THEN BEGIN
                    IsServc := 'N';
                    PrdDesc := TransferShipmentLine.Description + TransferShipmentLine."Description 2";
                    HsnCd := TransferShipmentLine."HSN/SAC Code";
                    //>>v1.03
                    Barcde := '';
                    PreTaxVal := ROUND(TransferShipmentLine.Quantity * TransferShipmentLine."Unit Price", 0.01, '=');//5002Fix
                    OrdLineRef := TransferShipmentLine."Line No.";
                    OrgCntry := 'IN';
                    PrdSlNo := '';
                    //<<v1.03
                    Qty := TransferShipmentLine.Quantity;
                    FreeQty := 0;
                    IF TransferShipmentLine."GST Assessable Value" <> 0 THEN
                        AssAmt := TransferShipmentLine."GST Assessable Value"
                    ELSE
                        AssAmt := TransferShipmentLine.Amount;
                    IF UOM.GET(TransferShipmentLine."Unit of Measure Code") THEN
                        Unit := COPYSTR(UOM.Code, 1, 3);
                    UnitPrice := TransferShipmentLine."Unit Price";
                    TotAmt := TransferShipmentLine.Amount;
                    Discount := 0;//v1.03

                    GetGSTCompRate(TransferShipmentLine."Document No.", TransferShipmentLine."Line No.",
                      GstRt, CgstAmt, SgstAmt, IgstAmt, CesRt, CesAmt, CesNonAdvlAmt, StateCesRt, StateCesAmt, StateCesNonAdvlAmt, TotGSTAmt);

                    OthChrg := 0;
                    TotItemVal := TransferShipmentLine.Amount + TotGSTAmt;  //Need to check

                    Item.GET(TransferShipmentLine."Item No.");
                    LotExist := Item."Item Tracking Code" <> '';
                    //>>v1.03
                    IF Item."Country/Region of Origin Code" <> '' THEN
                        OrgCntry := COPYSTR(Item."Country/Region of Origin Code", 1, 2);
                    //<<v1.03
                    LineNo := TransferShipmentLine."Line No.";
                END;
        //EInvTrans<<
        //EXPFIX >>

        IF PreTaxVal <> 0 THEN
            PreTaxVal := ROUND(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                        WORKDATE, CurrCode, PreTaxVal, CurrFactor), 0.01, '=');

        IF AssAmt <> 0 THEN
            AssAmt := ROUND(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                        WORKDATE, CurrCode, AssAmt, CurrFactor), 0.01, '=');

        IF UnitPrice <> 0 THEN
            UnitPrice := ROUND(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                        WORKDATE, CurrCode, UnitPrice, CurrFactor), 0.01, '=');

        IF TotAmt <> 0 THEN
            TotAmt := ROUND(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                        WORKDATE, CurrCode, TotAmt, CurrFactor), 0.01, '=');

        IF Discount <> 0 THEN
            Discount := ROUND(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                        WORKDATE, CurrCode, Discount, CurrFactor), 0.01, '=');

        IF OthChrg <> 0 THEN
            OthChrg := ROUND(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                        WORKDATE, CurrCode, OthChrg, CurrFactor), 0.01, '=');

        IF TotItemVal <> 0 THEN
            TotItemVal := ROUND(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                        WORKDATE, CurrCode, TotItemVal, CurrFactor), 0.01, '=');
        //EXPFIX <<

        IF SlNo <> 0 then begin
            SlNoL := FORMAT(Slno);
            JObjectItems.Add('SlNo', SlNoL)
        end else
            JObjectItems.Add('SlNo', JVOBJG.AsToken());
        if IsServc <> '' then
            JObjectItems.Add('IsServc', IsServc)
        else
            JObjectItems.Add('IsServc', JVOBJG.AsToken());
        if PrdDesc <> '' then
            JObjectItems.Add('PrdDesc', PrdDesc)
        else
            JObjectItems.Add('PrdDesc', JVOBJG.AsToken());
        if HsnCd <> '' then
            JObjectItems.Add('HsnCd', HsnCd)
        else
            JObjectItems.Add('HsnCd', JVOBJG.AsToken());
        if Barcde <> '' then
            JObjectItems.Add('Barcde', Barcde)
        else
            JObjectItems.Add('Barcde', JVOBJG.AsToken());

        JObjectItems.Add('Qty', Qty);
        JObjectItems.Add('FreeQty', FreeQty);
        if Unit <> '' then
            JObjectItems.Add('Unit', Unit)
        else
            JObjectItems.Add('Unit', JVOBJG.AsToken());
        JObjectItems.Add('UnitPrice', UnitPrice);
        JObjectItems.Add('TotAmt', TotAmt);
        JObjectItems.Add('Discount', Discount);
        JObjectItems.Add('PreTaxVal', PreTaxVal);
        JObjectItems.Add('AssAmt', AssAmt);
        JObjectItems.Add('GstRt', GstRt);
        JObjectItems.Add('SgstAmt', SgstAmt);
        JObjectItems.Add('IgstAmt', IgstAmt);
        JObjectItems.Add('CgstAmt', CgstAmt);
        JObjectItems.Add('CesRt', CesRt);
        JObjectItems.Add('CesAmt', CesAmt);
        JObjectItems.Add('CesNonAdvlAmt', CesNonAdvlAmt);
        JObjectItems.Add('StateCesRt', StateCesRt);
        JObjectItems.Add('StateCesAmt', StateCesAmt);
        JObjectItems.Add('StateCesNonAdvlAmt', StateCesNonAdvlAmt);
        JObjectItems.Add('OthChrg', OthChrg);
        JObjectItems.Add('TotItemVal', TotItemVal);
        OrderLineNolT := Format(OrdLineRef);
        JObjectItems.Add('OrdLineRef', OrderLineNolT);
        JObjectItems.Add('OrgCntry', OrgCntry);
        if PrdSlNo <> '' then
            JObjectItems.Add('PrdSlNo', PrdSlNo)
        else
            JObjectItems.Add('PrdSlNo', JVOBJG.AsToken());
        if LotExist then
            ReadBchDtls(LineNo)
        else
            JObjectItems.Add('BchDtls', JVOBJG.AsToken());
        JObjectItems.Add('AttribDtls', JVOBJG.AsToken());
        JObjItemArrayG.Add(JObjectItems);
        //B2B<<

    end;

    local procedure ReadBchDtls(LineNo: Integer);
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ValueEntry: Record 5802;
        ItemLedgerEntry: Record 32;
        ValueEntryRelation: Record 6508;
        ItemTrackingManagement: Codeunit 6500;
        InvoiceRowID: Text[250];
    begin
        IF IsInvoice THEN
            InvoiceRowID := ItemTrackingManagement.ComposeRowID(DATABASE::"Sales Invoice Line", 0, DocumentNo, '', 0, LineNo)
        ELSE
            IF CreditMemo THEN
                InvoiceRowID := ItemTrackingManagement.ComposeRowID(DATABASE::"Sales Cr.Memo Line", 0, DocumentNo, '', 0, LineNo)
            //EInvTrans>>
            ELSE
                IF TransferShipment THEN
                    InvoiceRowID := ItemTrackingManagement.ComposeRowID(DATABASE::"Transfer Shipment Line", 0, DocumentNo, '', 0, LineNo);
        //EInvTrans<<
        ValueEntryRelation.SETCURRENTKEY("Source RowId");
        ValueEntryRelation.SETRANGE("Source RowId", InvoiceRowID);
        IF ValueEntryRelation.FINDSET THEN BEGIN
            REPEAT
                ValueEntry.GET(ValueEntryRelation."Value Entry No.");
                ItemLedgerEntry.GET(ValueEntry."Item Ledger Entry No.");
                IF ItemLedgerEntry."Invoiced Quantity" <> 0 THEN
                    WriteBchDtls(
                      COPYSTR(ItemLedgerEntry."Lot No." + ItemLedgerEntry."Serial No.", 1, 20),
                      FORMAT(ItemLedgerEntry."Expiration Date", 0, '<Year4>-<Month,2>-<Day,2>'),
                      FORMAT(ItemLedgerEntry."Warranty Date", 0, '<Year4>-<Month,2>-<Day,2>'), JObjBactchLineG);
            UNTIL ValueEntryRelation.NEXT = 0;
            JObjVerG.Add('BchDtls', JObjBactchLineG);
        END;
    end;

    local procedure WriteBchDtls(Nm: Text[20]; ExpDt: Text[10]; WrDt: Text[10]; var JObjBchDtlsL: JsonObject);
    begin
        //B2B>>
        if Nm <> '' then
            JObjBchDtlsL.Add('Nm', Nm)
        else
            JObjBchDtlsL.Add('Nm', JVOBJG.AsToken());
        if ExpDt <> '' then
            JObjBchDtlsL.Add('ExpDt', ExpDt)
        else
            JObjBchDtlsL.Add('ExpDt', JVOBJG.AsToken());
        if WrDt <> '' then
            JObjBchDtlsL.Add('WrDt', WrDt)
        else
            JObjBchDtlsL.Add('WrDt', JVOBJG.AsToken());
        //B2B<<
    end;

    local procedure ReadPayDtls();
    var
        Nm: Text[100];
        AccDet: Text[18];
        Mode: Text[18];
        FinInsBr: Text[11];
        PayTerm: Text[100];
        PayInstr: Text[100];
        CrTrn: Text[100];
        DirDr: Text[100];
        CrDay: Integer;
        PaidAmt: Decimal;
        PaymtDue: Decimal;
    begin
        IF IsInvoice THEN BEGIN
            Nm := '';//Payee Name
            AccDet := '';//Bank Account No.
            Mode := '';//Mode of Payment: Cash, Credit, Direct Transfer
            FinInsBr := '';//Branch or IFSC code
            PayTerm := '';//Term of Payment
            PayInstr := '';//Pay Instruction
            CrTrn := '';//Credit Transfer
            DirDr := '';//Direct Debit
            CrDay := 0;//Credit Days
            PaidAmt := 0;//The sum of amount paid in advance
            PaymtDue := 0;//Outstanding amount
        END ELSE
            IF CreditMemo THEN BEGIN
                Nm := '';//Payee Name
                AccDet := '';//Bank Account No.
                Mode := '';//Mode of Payment: Cash, Credit, Direct Transfer
                FinInsBr := '';//Branch or IFSC code
                PayTerm := '';//Term of Payment
                PayInstr := '';//Pay Instruction
                CrTrn := '';//Credit Transfer
                DirDr := '';//Direct Debit
                CrDay := 0;//Credit Days
                PaidAmt := 0;//The sum of amount paid in advance
                PaymtDue := 0;//Outstanding amount
                              //EInvTrans>>
            END ELSE
                IF TransferShipment THEN BEGIN
                    Nm := '';//Payee Name
                    AccDet := '';//Bank Account No.
                    Mode := '';//Mode of Payment: Cash, Credit, Direct Transfer
                    FinInsBr := '';//Branch or IFSC code
                    PayTerm := '';//Term of Payment
                    PayInstr := '';//Pay Instruction
                    CrTrn := '';//Credit Transfer
                    DirDr := '';//Direct Debit
                    CrDay := 0;//Credit Days
                    PaidAmt := 0;//The sum of amount paid in advance
                    PaymtDue := 0;//Outstanding amount
                END;
        //EInvTrans<<
        IF (Nm = '') AND (AccDet = '') AND (Mode = '') AND (FinInsBr = '') AND (PayTerm = '') AND (PayInstr = '') AND
          (CrTrn = '') AND (DirDr = '') AND (CrDay = 0) AND (PaidAmt = 0) AND (PaymtDue = 0)
        THEN BEGIN
            JObjVerG.Add('PayDtls', JVOBJG.AsToken());
        END ELSE
            WritePayDtls(Nm, AccDet, Mode, FinInsBr, PayTerm, PayInstr, CrTrn, DirDr, CrDay, PaidAmt, PaymtDue);
    end;

    local procedure WritePayDtls(Nm: Text[100]; AccDet: Text[18]; Mode: Text[18]; FinInsBr: Text[11]; PayTerm: Text[100]; PayInstr: Text[100]; CrTrn: Text[100]; DirDr: Text[100]; CrDay: Integer; PaidAmt: Decimal; PaymtDue: Decimal);
    begin
        //B2B>>
        if Nm <> '' then
            JObjPayDtlsG.Add('Nm', Nm)
        else
            JObjPayDtlsG.Add('Nm', JVOBJG.AsToken());
        if AccDet <> '' then
            JObjPayDtlsG.Add('AccDet', AccDet)
        else
            JObjPayDtlsG.Add('AccDet', JVOBJG.AsToken());
        if Mode <> '' then
            JObjPayDtlsG.Add('Mode', Mode)
        else
            JObjPayDtlsG.Add('Mode', JVOBJG.AsToken());

        if FinInsBr <> '' then
            JObjPayDtlsG.Add('FinInsBr', FinInsBr)
        else
            JObjPayDtlsG.Add('FinInsBr', JVOBJG.AsToken());
        if PayTerm <> '' then
            JObjPayDtlsG.Add('PayTerm', PayTerm)
        else
            JObjPayDtlsG.Add('PayTerm', JVOBJG.AsToken());
        if PayInstr <> '' then
            JObjPayDtlsG.Add('PayInstr', PayInstr)
        else
            JObjPayDtlsG.Add('PayInstr', JVOBJG.AsToken());
        if CrTrn <> '' then
            JObjPayDtlsG.Add('CrTrn', CrTrn)
        else
            JObjPayDtlsG.Add('CrTrn', JVOBJG.AsToken());
        if DirDr <> '' then
            JObjPayDtlsG.Add('DirDr', DirDr)
        else
            JObjPayDtlsG.Add('DirDr', JVOBJG.AsToken());
        if CrDay <> 0 then
            JObjPayDtlsG.Add('CrDay', CrDay)
        else
            JObjPayDtlsG.Add('CrDay', JVOBJG.AsToken());
        if PaidAmt <> 0 then
            JObjPayDtlsG.Add('PaidAmt', PaidAmt)
        else
            JObjPayDtlsG.Add('PaidAmt', JVOBJG.AsToken());
        if PaymtDue <> 0 then
            JObjPayDtlsG.Add('PaymtDue', PaymtDue)
        else
            JObjPayDtlsG.Add('PaymtDue', JVOBJG.AsToken());
        JObjVerG.Add('PayDtls', JObjPayDtlsG);
        //B2B<<
    end;

    local procedure ReadRefDtls();
    var
        InvRm: Text[100];
        InvStDt: Text[10];
        InvEndDt: Text[10];
        InvNo: Text[16];
        InvDt: Text[10];
        OthRefNo: Text[20];
        RecAdvRefr: Text[20];
        RecAdvDt: Text[10];
        TendRefr: Text[20];
        ContrRefr: Text[20];
        ExtRefr: Text[20];
        ProjRefr: Text[20];
        PORefr: Text[16];
        PORefDt: Text[10];
    begin
        IF IsInvoice THEN BEGIN
            InvRm := '';//Remarks/Note
            InvStDt := '';//Invoice Start Date
            InvEndDt := '';//Invoice End Date

            InvNo := '';//Reference of Original Invoice if any
            InvDt := '';//Date of preceding invoice
            OthRefNo := '';//Other Reference

            RecAdvRefr := '';//Receipt Advice No.
            RecAdvDt := '';//Date of Receipt Advice
            TendRefr := '';//Lot/Batch Reference No.
            ContrRefr := '';//Contract Reference No.
            ExtRefr := '';//Any other Reference
            ProjRefr := '';//Project Reference No.
            PORefr := '';//Vendor PO Reference No.
            PORefDt := '';//Vendor PO Reference Date
        END ELSE
            IF CreditMemo THEN BEGIN
                InvRm := '';//Remarks/Note
                InvStDt := '';//Invoice Start Date
                InvEndDt := '';//Invoice End Date

                InvNo := '';//Reference of Original Invoice if any
                InvDt := '';//Date of preceding invoice
                OthRefNo := '';//Other Reference

                RecAdvRefr := '';//Receipt Advice No.
                RecAdvDt := '';//Date of Receipt Advice
                TendRefr := '';//Lot/Batch Reference No.
                ContrRefr := '';//Contract Reference No.
                ExtRefr := '';//Any other Reference
                ProjRefr := '';//Project Reference No.
                PORefr := '';//Vendor PO Reference No.
                PORefDt := '';//Vendor PO Reference Date
                              //EInvTrans>>
            END ELSE
                IF TransferShipment THEN BEGIN
                    InvRm := '';//Remarks/Note
                    InvStDt := '';//Invoice Start Date
                    InvEndDt := '';//Invoice End Date

                    InvNo := '';//Reference of Original Invoice if any
                    InvDt := '';//Date of preceding invoice
                    OthRefNo := '';//Other Reference

                    RecAdvRefr := '';//Receipt Advice No.
                    RecAdvDt := '';//Date of Receipt Advice
                    TendRefr := '';//Lot/Batch Reference No.
                    ContrRefr := '';//Contract Reference No.
                    ExtRefr := '';//Any other Reference
                    ProjRefr := '';//Project Reference No.
                    PORefr := '';//Vendor PO Reference No.
                    PORefDt := '';//Vendor PO Reference Date
                END;
        //EInvTrans<<
        IF (InvRm = '') AND (InvStDt = '') AND (InvEndDt = '') AND
          (InvNo = '') AND (InvDt = '') AND (OthRefNo = '') AND
          (RecAdvRefr = '') AND (RecAdvDt = '') AND (TendRefr = '') AND (ContrRefr = '') AND
          (ExtRefr = '') AND (ProjRefr = '') AND (PORefr = '') AND (PORefDt = '')
        THEN BEGIN
            JObjVerG.Add('RefDtls', JVOBJG.AsToken());

        END ELSE
            WriteRefDtls(InvRm, InvStDt, InvEndDt, InvNo, InvDt, OthRefNo, RecAdvRefr, RecAdvDt, TendRefr, ContrRefr, ExtRefr, ProjRefr, PORefr, PORefDt);
    end;

    local procedure WriteRefDtls(InvRm: Text[100]; InvStDt: Text[10]; InvEndDt: Text[10]; InvNo: Text[16]; InvDt: Text[10]; OthRefNo: Text[20]; RecAdvRefr: Text[20]; RecAdvDt: Text[10]; TendRefr: Text[20]; ContrRefr: Text[20]; ExtRefr: Text[20]; ProjRefr: Text[20]; PORefr: Text[16]; PORefDt: Text[10]);
    begin

        //B2B>>
        if InvRm <> '' then
            JObjRefDtlsG.Add('InvRm', InvRm)
        else
            JObjRefDtlsG.Add('InvRm', JVOBJG.AsToken());
        if InvStDt <> '' then
            JObjRefDtlsG.Add('InvStDt', InvStDt)
        else
            JObjRefDtlsG.Add('InvStDt', JVOBJG.AsToken());
        if InvEndDt <> '' then
            JObjRefDtlsG.Add('InvEndDt', InvEndDt)
        else
            JObjRefDtlsG.Add('InvEndDt', JVOBJG.AsToken());
        JObjVerG.Add('RefDtls', JObjRefDtlsG);

        //B2B<<
        WritePrecDocDtls(InvNo, InvDt, OthRefNo);

        WriteContrDtls(RecAdvRefr, RecAdvDt, TendRefr, ContrRefr, ExtRefr, ProjRefr, PORefr, PORefDt);
    end;

    local procedure WritePrecDocDtls(InvNo: Text[16]; InvDt: Text[10]; OthRefNo: Text[20]);
    begin

        //B2B>>
        JObjVerG.Add('PrecDocDtls', '');
        JObjPreDtlsG.Add('InvNo', '');
        JObjPreDtlsG.Add('InvDt', '');
        JObjPreDtlsG.Add('OthRefNo', '');
        repeat
            if InvNo <> '' then
                JObjPreDtlsG.Add('InvNo', InvNo)
            else
                JObjPreDtlsG.Add('InvNo', JVOBJG.AsToken());
            if InvDt <> '' then
                JObjPreDtlsG.Add('InvDt', '')
            else
                JObjPreDtlsG.Add('InvDt', JVOBJG.AsToken());
            if OthRefNo <> '' then
                JObjPreDtlsG.Add('OthRefNo', '')
            else
                JObjPreDtlsG.Add('OthRefNo', JVOBJG.AsToken());
            JSArrayPreDtlsG.Add(JObjPreDtlsG);
        until true;
        JObjVerG.Add('PrecDocument', JSArrayPreDtlsG);
        //B2B<<
    end;

    local procedure WriteContrDtls(RecAdvRefr: Text[20]; RecAdvDt: Text[10]; TendRefr: Text[20]; ContrRefr: Text[20]; ExtRefr: Text[20]; ProjRefr: Text[20]; PORefr: Text[16]; PORefDt: Text[10]);
    begin

        //B2B>>
        JObjVerG.Add('ContrDtls', '');
        JObjContrlDtlsG.Add('RecAdvRefr', '');
        JObjContrlDtlsG.Add('RecAdvDt', '');
        JObjContrlDtlsG.Add('TendRefr', '');
        JObjContrlDtlsG.Add('ContrRefr', '');
        JObjContrlDtlsG.Add('ExtRefr', '');
        JObjContrlDtlsG.Add('ProjRefr', '');
        JObjContrlDtlsG.Add('PORefDt', '');
        repeat
            if RecAdvRefr <> '' then
                JObjContrlDtlsG.Add('RecAdvRefr', RecAdvRefr)
            else
                JObjContrlDtlsG.Add('RecAdvRefr', JVOBJG.AsToken());
            if RecAdvDt <> '' then
                JObjContrlDtlsG.Add('RecAdvDt', RecAdvDt)
            else
                JObjContrlDtlsG.Add('RecAdvDt', JVOBJG.AsToken());
            if TendRefr <> '' then
                JObjContrlDtlsG.Add('TendRefr', '')
            else
                JObjContrlDtlsG.Add('TendRefr', JVOBJG.AsToken());
            if ContrRefr <> '' then
                JObjContrlDtlsG.Add('ContrRefr', ContrRefr)
            else
                JObjContrlDtlsG.Add('ContrRefr', JVOBJG.AsToken());
            if ExtRefr <> '' then
                JObjContrlDtlsG.Add('ExtRefr', ExtRefr)
            else
                JObjContrlDtlsG.Add('ExtRefr', JVOBJG.AsToken());
            if ProjRefr <> '' then
                JObjContrlDtlsG.Add('ProjRefr', ProjRefr)
            else
                JObjContrlDtlsG.Add('ProjRefr', JVOBJG.AsToken());
            if PORefDt <> '' then
                JObjContrlDtlsG.Add('PORefDt', PORefDt)
            else
                JObjContrlDtlsG.Add('PORefDt', JVOBJG.AsToken());
            JArryContrlDtlsG.Add(JObjContrlDtlsG);
        until true;
        JObjVerG.Add('Contract', JArryContrlDtlsG);
        //B2B<<
    end;

    local procedure ReadAddlDocDtls();
    var
        Url: Text[100];
        Docs: Text;
        Info: Text;
    begin
        IF IsInvoice THEN BEGIN
            Url := '';//Supporting Document URL
            Docs := '';//Supporting document in Base64 Format
            Info := '';//Any additional info
        END ELSE
            IF CreditMemo THEN BEGIN
                Url := '';//Supporting Document URL
                Docs := '';//Supporting document in Base64 Format
                Info := '';//Any additional info
                           //EInvTrans>>
            END ELSE
                IF TransferShipment THEN BEGIN
                    Url := '';//Supporting Document URL
                    Docs := '';//Supporting document in Base64 Format
                    Info := '';//Any additional info
                END;
        //EInvTrans>>
        IF (Url = '') AND (Docs = '') AND (Info = '') THEN BEGIN
            JObjVerG.Add('AddlDocDtls', JVOBJG.AsToken());
        END ELSE BEGIN
            JObjVerG.Add('AddlDocDtls', '');
            REPEAT
                WriteAddlDocDtls(Url, Docs, Info, JSODcoDtlsG);
                JSArryDocDtlsG.Add(JSODcoDtlsG);
            UNTIL TRUE;
            JObjVerG.Add('AddlDocument', JSArryDocDtlsG);
        END;
    end;

    local procedure WriteAddlDocDtls(Url: Text[100]; Docs: Text; Info: Text; var JSODcoDtlsL: JsonObject);
    begin
        if Url <> '' then
            JSODcoDtlsL.Add('Url', Url)
        else
            JSODcoDtlsL.Add('Url', JVOBJG.AsToken());
        if Docs <> '' then
            JSODcoDtlsL.Add('Docs', Docs)
        else
            JSODcoDtlsL.Add('Docs', JVOBJG.AsToken());
        if Info <> '' then
            JSODcoDtlsL.Add('Info', Info)
        else
            JSODcoDtlsL.Add('Info', JVOBJG.AsToken());

    end;

    local procedure ReadValDtls();
    var
        AssVal: Decimal;
        CgstVal: Decimal;
        SgstVal: Decimal;
        IgstVal: Decimal;
        CesVal: Decimal;
        StCesVal: Decimal;
        CesNonAdval: Decimal;
        Disc: Decimal;
        OthChrg: Decimal;
        TotInvVal: Decimal;
        RndOffAmt: Decimal;
        TotInvValFc: Decimal;
    begin
        GetGSTVal(AssVal, CgstVal, SgstVal, IgstVal, CesVal, StCesVal, CesNonAdval, Disc, OthChrg, TotInvVal, TotInvValFc);
        RndOffAmt := GetRndOffAmt;
        WriteValDtls(AssVal, CgstVal, SgstVal, IgstVal, CesVal, StCesVal, Disc, OthChrg, RndOffAmt, TotInvVal, TotInvValFc);
    end;

    local procedure WriteValDtls(Assval: Decimal; CgstVal: Decimal; SgstVAl: Decimal; IgstVal: Decimal; CesVal: Decimal; StCesVal: Decimal; Disc: Decimal; OthChrg: Decimal; RndOffAmt: Decimal; TotInvVal: Decimal; TotInvValFc: Decimal);
    begin
        //v1.03 Disc, OthChrg and TotInvValFc parameters and related code added

        //B2BSaas>>
        JSOBJValG.Add('AssVal', Assval);
        JSOBJValG.Add('CgstVal', CgstVal);
        JSOBJValG.Add('SgstVal', SgstVAl);
        JSOBJValG.Add('IgstVal', IgstVal);
        JSOBJValG.Add('CesVal', CesVal);
        JSOBJValG.Add('StCesVal', StCesVal);
        JSOBJValG.Add('Disc', Disc);
        JSOBJValG.Add('OthChrg', OthChrg);
        JSOBJValG.Add('RndOffAmt', RndOffAmt);
        JSOBJValG.Add('TotInvVal', TotInvVal);
        JSOBJValG.Add('TotInvValFc', TotInvValFc);
        JObjVerG.Add('ValDtls', JSOBJValG);
        //B2BSaas<<
    end;

    procedure SetSalesInvHeader(SalesInvoiceHeaderBuff: Record "Sales Invoice Header");
    begin
        SalesInvoiceHeader := SalesInvoiceHeaderBuff;
        IsInvoice := TRUE;
    end;

    procedure SetCrMemoHeader(SalesCrMemoHeaderBuff: Record "Sales Cr.Memo Header");
    begin
        SalesCrMemoHeader := SalesCrMemoHeaderBuff;
        CreditMemo := TRUE;
    end;

    local procedure GetRefInvNo(DocNo: Code[20]) RefInvNo: Code[20];
    var
        ReferenceInvoiceNo: Record "Reference Invoice No.";
    begin
        ReferenceInvoiceNo.SETRANGE("Document No.", DocNo);
        IF ReferenceInvoiceNo.FINDFIRST THEN
            RefInvNo := ReferenceInvoiceNo."Reference Invoice Nos."
        ELSE
            RefInvNo := '';
    end;

    local procedure GetGSTCompRate(DocNo: Code[20]; LineNo: Integer; var GstRt: Decimal; var CgstAmt: Decimal; var SgstAmt: Decimal; var IgstAmt: Decimal; var CesRt: Decimal; var CessAmt: Decimal; var CesNonAdvlAmt: Decimal; var StateCesRt: Decimal; var StateCesAmt: Decimal; var StateCesNonAdvlAmt: Decimal; var TotGSTAmt: Decimal);
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        GSTComponent: Record "Tax Component";
        CurrExchRate: Record 330;
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        TotalGSTAmount: Decimal;
        CurrencyCode: code[10];
        CurrencyFactor: Decimal;
        TransferShipmentLine: Record "Transfer Shipment Line";
    begin
        DetailedGSTLedgerEntry.SETRANGE("Document No.", DocNo);
        DetailedGSTLedgerEntry.SETRANGE("Document Line No.", LineNo);

        CesRt := 0;
        CessAmt := 0;
        CesNonAdvlAmt := 0;
        DetailedGSTLedgerEntry.SETRANGE("GST Component Code", 'CESS');
        IF DetailedGSTLedgerEntry.FINDFIRST THEN
            IF DetailedGSTLedgerEntry."GST %" > 0 THEN BEGIN
                CesRt := DetailedGSTLedgerEntry."GST %";
                CessAmt := ABS(DetailedGSTLedgerEntry."GST Amount");
            END ELSE
                CesNonAdvlAmt := ABS(DetailedGSTLedgerEntry."GST Amount");

        DetailedGSTLedgerEntry.SETRANGE("GST Component Code", 'INTERCESS');
        IF DetailedGSTLedgerEntry.FINDFIRST THEN BEGIN
            CesRt += DetailedGSTLedgerEntry."GST %";
            CessAmt += ABS(DetailedGSTLedgerEntry."GST Amount");
        END;

        StateCesRt := 0;
        StateCesAmt := 0;
        StateCesNonAdvlAmt := 0;
        DetailedGSTLedgerEntry.SETRANGE("GST Component Code");
        IF DetailedGSTLedgerEntry.FINDSET THEN
            REPEAT
                IF NOT (DetailedGSTLedgerEntry."GST Component Code" IN ['CGST', 'SGST', 'IGST', 'CESS', 'INTERCESS']) THEN
                    IF GSTComponent.GET(DetailedGSTLedgerEntry."GST Component Code") THEN
                        //IF GSTComponent."Exclude from Reports" THEN //B2BUPG1.0
                        IF GSTComponent."Visible On Interface" THEN
                            IF DetailedGSTLedgerEntry."GST %" > 0 THEN BEGIN
                                StateCesRt := DetailedGSTLedgerEntry."GST %";
                                StateCesAmt := ABS(DetailedGSTLedgerEntry."GST Amount");
                            END ELSE
                                StateCesNonAdvlAmt := ABS(DetailedGSTLedgerEntry."GST Amount");
            UNTIL DetailedGSTLedgerEntry.NEXT = 0;


        //LCY to FCY conversion
        IF IsInvoice THEN BEGIN
            CurrencyCode := SalesInvoiceHeader."Currency Code";
            CurrencyFactor := SalesInvoiceHeader."Currency Factor";
        END ELSE BEGIN
            CurrencyCode := SalesCrMemoHeader."Currency Code";
            CurrencyFactor := SalesCrMemoHeader."Currency Factor";
        END;

        IF CessAmt <> 0 THEN
            CessAmt := ROUND(CurrExchRate.ExchangeAmtLCYToFCY(WORKDATE, CurrencyCode, CessAmt, CurrencyFactor), 1, '=');
        IF CesNonAdvlAmt <> 0 THEN
            CesNonAdvlAmt := ROUND(CurrExchRate.ExchangeAmtLCYToFCY(WORKDATE, CurrencyCode, CesNonAdvlAmt, CurrencyFactor), 1, '=');
        IF StateCesAmt <> 0 THEN
            StateCesAmt := ROUND(CurrExchRate.ExchangeAmtLCYToFCY(WORKDATE, CurrencyCode, StateCesAmt, CurrencyFactor), 1, '=');
        IF StateCesNonAdvlAmt <> 0 THEN
            StateCesNonAdvlAmt := ROUND(CurrExchRate.ExchangeAmtLCYToFCY(WORKDATE, CurrencyCode, StateCesNonAdvlAmt, CurrencyFactor), 1, '=');
        //EXPFIX

        /*GstRt := 0;
        CgstAmt := 0;
        SgstAmt := 0;
        IgstAmt := 0;*/


        IF IsInvoice THEN BEGIN
            SalesInvoiceLine.GET(DocNo, LineNo);
            //B2BUPG1.0>>
            //TotalGSTAmount := SalesInvoiceLine."Total GST Amount";
            TotalGSTAmount := TotGSTAmt;
            //B2BUPG1.0<<
        END ELSE
            IF CreditMemo THEN BEGIN
                SalesCrMemoLine.GET(DocNo, LineNo);
                //B2BUPG1.0>>
                //TotalGSTAmount := SalesCrMemoLine."Total GST Amount";
                TotalGSTAmount := TotGSTAmt;
                //B2BUPG1.0<<
                //EInvTrans>>
            END ELSE
                IF TransferShipment THEN BEGIN
                    TransferShipmentLine.GET(DocNo, LineNo);
                    TotalGSTAmount := TotGSTAmt;
                END;
        //EInvTrans<<
        //EXPFIX >>
        IF TotalGSTAmount <> 0 THEN
            TotalGSTAmount := ROUND(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                        WORKDATE, CurrCode, TotalGSTAmount, CurrFactor), 0.01, '=');
        //EXPFIX <<
        TotalGSTAmount := TotalGSTAmount - (CessAmt + StateCesAmt + CesNonAdvlAmt + StateCesNonAdvlAmt);//v1.03
        DetailedGSTLedgerEntry.SETRANGE("GST Component Code");
        IF DetailedGSTLedgerEntry.FINDFIRST THEN
            CASE DetailedGSTLedgerEntry."GST Component Code" OF
                'IGST':
                    BEGIN
                        GstRt := DetailedGSTLedgerEntry."GST %";
                        IgstAmt := Abs(DetailedGSTLedgerEntry."GST Amount");
                    END;
                'CGST', 'SGST':
                    BEGIN
                        GstRt := 2 * DetailedGSTLedgerEntry."GST %";
                        CgstAmt := Abs(DetailedGSTLedgerEntry."GST Amount");
                        SgstAmt := Abs(DetailedGSTLedgerEntry."GST Amount");
                    END;
            END;
        TotGSTAmt := CgstAmt + SgstAmt + IgstAmt + CessAmt + StateCesAmt + CesNonAdvlAmt + StateCesNonAdvlAmt;

    end;

    local procedure GetGSTVal(var AssVal: Decimal; var CgstVal: Decimal; var SgstVal: Decimal; var IgstVal: Decimal; var CesVal: Decimal; var StCesVal: Decimal; var CesNonAdval: Decimal; var Disc: Decimal; var OthChrg: Decimal; var TotInvVal: Decimal; var TotInvValFc: Decimal);
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        GSTLedgerEntry: Record "GST Ledger Entry";
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        CurrExchRate: Record 330;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GSTComponent: Record "Tax Component";
        TotGSTAmt: Decimal;
        IsSEZorExported: Boolean;
        //B2BUPG1.0>> 
        CGSTValue: Decimal;
        SGSTValue: Decimal;
        IGSTValue: Decimal;
        CESSValue: Decimal;
        //B2BUPG1.0<<
        TransferShipmentLine: Record "Transfer Shipment Line";
    begin
        GSTLedgerEntry.SETRANGE("Entry Type", GSTLedgerEntry."Entry Type"::"Initial Entry");//BugFix
        GSTLedgerEntry.SETRANGE("Document No.", DocumentNo);

        IF IsInvoice THEN BEGIN
            SalesInvoiceLine.SETRANGE("Document No.", DocumentNo);
            SalesInvoiceLine.SETFILTER(Quantity, '<>%1', 0);//BugFix
            IF SalesInvoiceLine.FINDSET THEN
                REPEAT
                    AssVal += SalesInvoiceLine.Amount;
                    //B2BUPG1.0>> - Modified due to removing of fields
                    //TotGSTAmt += SalesInvoiceLine."Total GST Amount";
                    GetGSTValueForLine(SalesInvoiceLine."Line No.", CGSTValue, SGSTValue, IGSTValue, CESSValue);
                    TotGSTAmt += CGSTValue + SGSTValue + IGSTValue + CESSValue;
                    //B2BUPG1.0<<
                    Disc += SalesInvoiceLine."Inv. Discount Amount";
                    //OthChrg += SalesInvoiceLine."Charges To Customer" + SalesInvoiceLine."TDS/TCS Amount";//v1.03
                    //B2BUPG1.0>>
                    //OthChrg += SalesInvoiceLine."Charges To Customer" + SalesInvoiceLine."Total TDS/TCS Incl. SHE CESS";//v1.03
                    OthChrg := 0;
                //B2BUPG1.0<<
                UNTIL SalesInvoiceLine.NEXT = 0;
        END ELSE
            IF CreditMemo THEN BEGIN
                SalesCrMemoLine.SETRANGE("Document No.", DocumentNo);
                SalesCrMemoLine.SETFILTER(Quantity, '<>%1', 0);//BugFix
                IF SalesCrMemoLine.FINDSET THEN
                    REPEAT
                        AssVal += SalesCrMemoLine.Amount;
                        //B2BUPG1.0>> - Modified due to removing of fields
                        //TotGSTAmt += SalesCrMemoLine."Total GST Amount";
                        GetGSTValueForLine(SalesCrMemoLine."Line No.", CGSTValue, SGSTValue, IGSTValue, CESSValue);
                        TotGSTAmt += CGSTValue + SGSTValue + IGSTValue + CESSValue;
                        //B2BUPG1.0<<
                        Disc += SalesCrMemoLine."Inv. Discount Amount";
                        //OthChrg += SalesCrMemoLine."Charges To Customer" + SalesCrMemoLine."TDS/TCS Amount";//v1.03
                        //B2BUPG1.0>>
                        //OthChrg += SalesCrMemoLine."Charges To Customer" + SalesCrMemoLine."Total TDS/TCS Incl SHE CESS";//v1.03
                        OthChrg := 0;
                    //B2BUPG1.0<<
                    UNTIL SalesCrMemoLine.NEXT = 0;
                //EInvTrans>>
            END ELSE
                IF TransferShipment THEN BEGIN
                    TransferShipmentLine.SETRANGE("Document No.", DocumentNo);
                    TransferShipmentLine.SETFILTER(Quantity, '<>%1', 0);//BugFix
                    IF TransferShipmentLine.FINDSET THEN
                        REPEAT
                            AssVal += TransferShipmentLine.Amount;
                            GetGSTValueForLine(SalesCrMemoLine."Line No.", CGSTValue, SGSTValue, IGSTValue, CESSValue);
                            TotGSTAmt += CGSTValue + SGSTValue + IGSTValue + CESSValue;
                            Disc += 0;//TransferShipmentLine."Inv. Discount Amount";
                                      //OthChrg += SalesCrMemoLine."Charges To Customer" + SalesCrMemoLine."TDS/TCS Amount";//v1.03
                            OthChrg += TransferShipmentLine."Custom Duty Amount"; //+} TransferShipmentLine."Total TDS/TCS Incl SHE CESS";//v1.03
                        UNTIL TransferShipmentLine.NEXT = 0;
                END;
        //EInvTrans<<
        CesVal := 0;
        CesNonAdval := 0;
        GSTLedgerEntry.SETRANGE("GST Component Code", 'INTERCESS');
        IF GSTLedgerEntry.FINDSET THEN
            REPEAT
                CesVal += ABS(GSTLedgerEntry."GST Amount")
            UNTIL GSTLedgerEntry.NEXT = 0;

        DetailedGSTLedgerEntry.SETRANGE("Document No.", DocumentNo);
        DetailedGSTLedgerEntry.SETRANGE("GST Component Code", 'CESS');
        IF DetailedGSTLedgerEntry.FINDFIRST THEN
            REPEAT
                IF DetailedGSTLedgerEntry."GST %" > 0 THEN
                    CesVal += ABS(DetailedGSTLedgerEntry."GST Amount")
                ELSE
                    CesNonAdval += ABS(DetailedGSTLedgerEntry."GST Amount");
            UNTIL DetailedGSTLedgerEntry.NEXT = 0; //BugFixCess

        GSTLedgerEntry.SETFILTER("GST Component Code", '<>CGST&<>SGST&<>IGST&<>CESS&<>INTERCESS');//BugFix
        IF GSTLedgerEntry.FINDSET THEN BEGIN
            REPEAT
                IF GSTComponent.GET(GSTLedgerEntry."GST Component Code") THEN
                    //IF GSTComponent."Exclude from Reports" THEN //B2BUPG1.0
                        StCesVal += ABS(GSTLedgerEntry."GST Amount");
            UNTIL GSTLedgerEntry.NEXT = 0;
        END;

        IF IsInvoice THEN BEGIN
            //CurrencyCode := SalesInvoiceHeader."Currency Code";
            //CurrencyFactor := SalesInvoiceHeader."Currency Factor";
            IsSEZorExported := SalesInvoiceHeader."GST Customer Type" IN [SalesInvoiceHeader."GST Customer Type"::"SEZ Development",
                                                                          SalesInvoiceHeader."GST Customer Type"::"SEZ Unit",
                                                                          SalesInvoiceHeader."GST Customer Type"::Export];//v1.03
        END ELSE
            IF CreditMemo THEN BEGIN
                //CurrencyCode := SalesCrMemoHeader."Currency Code";
                //CurrencyFactor := SalesCrMemoHeader."Currency Factor";
                IsSEZorExported := SalesCrMemoHeader."GST Customer Type" IN [SalesCrMemoHeader."GST Customer Type"::"SEZ Development",
                                                                              SalesCrMemoHeader."GST Customer Type"::"SEZ Unit",
                                                                              SalesCrMemoHeader."GST Customer Type"::Export];//v1.03
                                                                                                                             //EInvTrans>>
            END ELSE
                IF TransferShipment THEN BEGIN
                    //CurrencyCode := SalesCrMemoHeader."Currency Code";
                    //CurrencyFactor := SalesCrMemoHeader."Currency Factor";
                    IsSEZorExported := FALSE;/*SalesCrMemoHeader."GST Customer Type" IN [SalesCrMemoHeader."GST Customer Type"::"SEZ Development",  //Need to check
                                                                        SalesCrMemoHeader."GST Customer Type"::"SEZ Unit",
                                                                        SalesCrMemoHeader."GST Customer Type"::Export];//v1.03*/
                END;
        //EInvTrans<<

        /*
        IF CesVal <> 0 THEN
          CesVal := ROUND(CurrExchRate.ExchangeAmtLCYToFCY(WORKDATE,CurrencyCode,CesVal,CurrencyFactor),1,'=');
        IF StCesVal <> 0 THEN
          StCesVal := ROUND(CurrExchRate.ExchangeAmtLCYToFCY(WORKDATE,CurrencyCode,StCesVal,CurrencyFactor),1,'=');
        IF CesNonAdval <> 0 THEN
          CesNonAdval := ROUND(CurrExchRate.ExchangeAmtLCYToFCY(WORKDATE,CurrencyCode,CesNonAdval,CurrencyFactor),1,'=');
        *///EXPFIX

        IgstVal := 0;
        CgstVal := 0;
        SgstVal := 0;

        //EXPFIX >>
        IF TotGSTAmt <> 0 THEN
            TotGSTAmt := ROUND(
                      CurrExchRate.ExchangeAmtFCYToLCY(
                      WORKDATE, CurrCode, TotGSTAmt, CurrFactor), 0.01, '=');
        //EXPFIX <<
        TotGSTAmt := TotGSTAmt - (CesVal + StCesVal + CesNonAdval);//v1.03

        GSTLedgerEntry.SETRANGE("GST Component Code");
        IF GSTLedgerEntry.FINDSET THEN
            CASE GSTLedgerEntry."GST Component Code" OF
                'IGST':
                    IgstVal := TotGSTAmt;
                'CGST', 'SGST':
                    BEGIN
                        CgstVal := TotGSTAmt / 2;
                        SgstVal := TotGSTAmt / 2;
                    END;
            END;

        CustLedgerEntry.SETCURRENTKEY("Document No.");
        CustLedgerEntry.SETRANGE("Document No.", DocumentNo);
        IF IsInvoice THEN BEGIN
            CustLedgerEntry.SETRANGE("Document Type", CustLedgerEntry."Document Type"::Invoice);
            CustLedgerEntry.SETRANGE("Customer No.", SalesInvoiceHeader."Bill-to Customer No.");
        END ELSE
            IF CreditMemo THEN BEGIN
                CustLedgerEntry.SETRANGE("Document Type", CustLedgerEntry."Document Type"::"Credit Memo");
                CustLedgerEntry.SETRANGE("Customer No.", SalesCrMemoHeader."Bill-to Customer No.");
            END;
        IF CustLedgerEntry.FINDFIRST THEN BEGIN
            CustLedgerEntry.CALCFIELDS(Amount);
            //>>v1.03
            TotInvVal := ABS(CustLedgerEntry.Amount);
            //EXPFIX >>
            IF TotInvVal <> 0 THEN
                TotInvVal := ROUND(
                           CurrExchRate.ExchangeAmtFCYToLCY(
                           WORKDATE, CurrCode, TotInvVal, CurrFactor), 0.01, '=');

            TotInvValFc := ABS(CustLedgerEntry.Amount);


            IF IsSEZorExported THEN BEGIN
                TotInvVal += TotGSTAmt + (CesVal + StCesVal + CesNonAdval);//v1.03
                TotInvValFc := ABS(CustLedgerEntry.Amount) + ROUND(CurrExchRate.ExchangeAmtLCYToFCY(WORKDATE,
                                                                  CurrCode, TotGSTAmt, CurrFactor), 0.01, '=')
                               + ROUND(CurrExchRate.ExchangeAmtLCYToFCY(WORKDATE,
                                                                  CurrCode, CesVal, CurrFactor), 0.01, '=')
                               + ROUND(CurrExchRate.ExchangeAmtLCYToFCY(WORKDATE,
                                                                  CurrCode, StCesVal, CurrFactor), 0.01, '=')
                               + ROUND(CurrExchRate.ExchangeAmtLCYToFCY(WORKDATE,
                                                                  CurrCode, CesNonAdval, CurrFactor), 0.01, '=');


            END;
            //EXPFIX <<
            //<<v1.03
        END;
        IF TransferShipment THEN
            TotInvVal := IgstVal + CgstVal + SgstVal + AssVal + OthChrg - Disc;
        //EXPFIX >>
        IF AssVal <> 0 THEN
            AssVal := ROUND(
                      CurrExchRate.ExchangeAmtFCYToLCY(
                      WORKDATE, CurrCode, AssVal, CurrFactor), 0.01, '=');

        IF Disc <> 0 THEN
            Disc := ROUND(
                      CurrExchRate.ExchangeAmtFCYToLCY(
                      WORKDATE, CurrCode, Disc, CurrFactor), 0.01, '=');

        IF OthChrg <> 0 THEN
            OthChrg := ROUND(
                      CurrExchRate.ExchangeAmtFCYToLCY(
                      WORKDATE, CurrCode, OthChrg, CurrFactor), 0.01, '=');
        //EXPFIX <<

    end;

    local procedure GetInvRoundingAcc(): Code[20];
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        CustPosGrpCode: Code[20];
    begin
        IF IsInvoice THEN
            CustPosGrpCode := SalesInvoiceHeader."Customer Posting Group"
        ELSE
            IF CreditMemo THEN
                CustPosGrpCode := SalesCrMemoHeader."Customer Posting Group"
            ELSE
                IF TransferShipment THEN
                    CustPosGrpCode := '';// TransferShipmentHeader.
        IF CustPosGrpCode = '' THEN
            EXIT('');
        CustomerPostingGroup.GET(CustPosGrpCode);
        EXIT(CustomerPostingGroup."Invoice Rounding Account");
    end;

    //B2BUPG1.0>> - Commented due to missing of fields.
    /*local procedure GetGSTRoundingAcc(): Code[20];
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.GET;
        EXIT(GLSetup."GST Inv. Rounding Account");
    end;*/
    //B2BUPG1.0<<

    local procedure GetRndOffAmt(): Decimal;
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        IF IsInvoice THEN BEGIN
            SalesInvoiceLine.SETRANGE("Document No.", SalesInvoiceHeader."No.");
            //B2BUPG1.0>>
            //SalesInvoiceLine.SETFILTER("No.", '%1|%2', GetInvRoundingAcc, GetGSTRoundingAcc);
            SalesInvoiceLine.SetFilter("No.", '%1', GetInvRoundingAcc);
            //B2BUPG1.0<<
            SalesInvoiceLine.CALCSUMS(Amount);
            EXIT(SalesInvoiceLine.Amount);
        END ELSE
            if CreditMemo then BEGIN
                SalesCrMemoLine.SETRANGE("Document No.", SalesCrMemoHeader."No.");
                //B2BUPG1.0>>
                //SalesCrMemoLine.SETFILTER("No.", '%1|%2', GetInvRoundingAcc, GetGSTRoundingAcc);
                SalesCrMemoLine.SetFilter("No.", '%1', GetInvRoundingAcc);
                //B2BUPG1.0<<
                SalesCrMemoLine.CALCSUMS(Amount);
                EXIT(SalesCrMemoLine.Amount);
                //EInvTrans>>
            END ELSE
                IF TransferShipment THEN BEGIN
                    //  TransferShipmentLine.SETRANGE("Document No.",TransferShipmentHeader."No.");
                    //  TransferShipmentLine.SETFILTER("Item No.",'%1|%2',GetInvRoundingAcc,GetGSTRoundingAcc);
                    //  TransferShipmentLine.CALCSUMS(Amount);  //Need to check
                    EXIT(0);
                END;
        //EInvTrans<<
    end;

    procedure CancelEInvoice(Variant: Variant): Boolean;
    var
        CancelSalesInvHdr: Record "Sales Invoice Header";
        CancelSalesCrMHdr: Record "Sales Cr.Memo Header";
        RecRef: RecordRef;
        //[RUNONCLIENT]
        //Windows: DotNet Interaction;
        CancelReason: Text;
        ReasonRemarks: Text;
        EInvoiceEntry: Record "E-Invoice Entry";
        CancelReport: Report "E-Invoice Cancel Reason";
        CancelTransferShipHdr: Record "Transfer Shipment Header";
        JSONCancelText: Text;
    begin
        RecRef.GETTABLE(Variant);
        CASE RecRef.NUMBER OF
            112:
                CancelSalesInvHdr := Variant;
            114:
                CancelSalesCrMHdr := Variant;
            5744:
                CancelTransferShipHdr := Variant;//EInvTrans
        END;
        //CancelReason := Windows.InputBox('Cancellation Reason :','Reason','',10,10);//Test
        //B2BUPG1.0>>
        //IF NOT OpenWindow(CancelReason, ReasonRemarks) THEN
        //    EXIT(FALSE);
        Clear(CancelReport);
        IF CancelSalesInvHdr."No." <> '' THEN
            CancelReport.SetValues(CancelSalesInvHdr."No.", true)
        ELSE
            CancelReport.SetValues(CancelSalesCrMHdr."No.", false);
        CancelReport.Run();
        //B2BUPG1.0<<

        IF CancelSalesInvHdr."No." <> '' THEN
            EInvoiceEntry.GET(EInvoiceEntry."Document Type"::"Sales Invoice", CancelSalesInvHdr."No.")
        ELSE
            IF CancelSalesCrMHdr."No." <> '' THEN
                EInvoiceEntry.GET(EInvoiceEntry."Document Type"::"Sales Cr. Memo", CancelSalesCrMHdr."No.")
            //EInvTrans>>
            ELSE
                IF CancelTransferShipHdr."No." <> '' THEN
                    EInvoiceEntry.GET(EInvoiceEntry."Document Type"::"Transfer Shipment", CancelTransferShipHdr."No.");
        //EInvTrans<<
        DocumentNo := EInvoiceEntry."Document No.";

        DocumentNo := EInvoiceEntry."Document No.";

        //B2BUPG1.0>>
        // EInvoiceEntry."IRN Cancelled Reason" := CancelReason;
        // EInvoiceEntry."IRN Cancelled Remarks" := ReasonRemarks;
        // EInvoiceEntry."IRN Cancelled By" := USERID;
        // EInvoiceEntry.MODIFY;
        CancelReason := EInvoiceEntry."IRN Cancelled Reason";
        ReasonRemarks := EInvoiceEntry."IRN Cancelled Remarks";
        //B2BUPG1.0<<

        JObJCancelG.Add('Irn', EInvoiceEntry."IRN No.");
        JObJCancelG.Add('CnlRsn', CancelReason);
        JObJCancelG.Add('CnlRem', ReasonRemarks);
        // ExportAsJson('Cancel_' + DocumentNo, JsonRequestPath);
        JObJCancelG.WriteTo(JSONCancelText);
        ExportAsJson('Cancel_' + DocumentNo, JsonRequestPath, JSONCancelText);//B2BESG21Jun2023
        EInvoiceLog.INIT;
        IF CancelSalesInvHdr."No." <> '' THEN
            EInvoiceLog."Document Type" := EInvoiceLog."Document Type"::Invoice
        ELSE
            IF CancelSalesCrMHdr."No." <> '' THEN
                EInvoiceLog."Document Type" := EInvoiceLog."Document Type"::"Credit Memo"
            //EInvTrans>>
            ELSE
                IF CancelTransferShipHdr."No." <> '' THEN
                    EInvoiceLog."Document Type" := EInvoiceLog."Document Type"::"Transfer Shipment";
        //EInvTrans<<
        EInvoiceLog."Document No." := DocumentNo;
        EInvoiceLog."Request Path" := JsonRequestPath;
        EInvoiceLog.Cancel := TRUE;
        EInvoiceLog.INSERT(true);
        EXIT(TRUE);
    end;

    /* local procedure OpenWindow(var ResonCode: Text; var ReasonRemarks: Text): Boolean;
     var
         [RUNONCLIENT]
         Prompt: DotNet FormDV;
         [RUNONCLIENT]
         FormBoarderStyle: DotNet FormBorderStyleDV;
         [RUNONCLIENT]
         FormStartPosition: DotNet FormStartPositionDV;
         [RUNONCLIENT]
         LblRows: DotNet LabelDV;
         [RUNONCLIENT]
         LblColumns: DotNet LabelDV;
         [RUNONCLIENT]
         TxtRows: DotNet TextBoxDV;
         [RUNONCLIENT]
         TxtColumns: DotNet TextBoxDV;
         [RUNONCLIENT]
         ButtonOk: DotNet ButtonDV;
         [RUNONCLIENT]
         ButtonCancel: DotNet ButtonDV;
         [RUNONCLIENT]
         DailogResult: DotNet DialogResultDV;
         CancelRemarksErr: Label 'Cancel Remarks must have a value';
         CancelReasonErr: Label 'Cancel Reason must have a value';
     begin
         Prompt := Prompt.Form();
         Prompt.Width := 350;
         Prompt.Height := 180;
         Prompt.FormBorderStyle := FormBoarderStyle.FixedDialog;

         Prompt.Text := 'Remarks';
         Prompt.StartPosition := FormStartPosition.CenterScreen;
         /*
         LblRows := LblRows.Label;
         LblRows.Text('Cancel Reason :');
         LblRows.Left(20);
         LblRows.Top(30);
         Prompt.Controls.Add(LblRows);
         */
    /* LblColumns := LblColumns.Label;
     LblColumns.Text('Cancel Remarks:');
     LblColumns.Left(20);
     LblColumns.Top(30);
     Prompt.Controls.Add(LblColumns);
     /*
     TxtRows := TxtRows.TextBox;
     TxtRows.Left(150);
     TxtRows.Top(30);
     TxtRows.Width(150);
     Prompt.Controls.Add(TxtRows);
     */
    /*TxtColumns := TxtColumns.TextBox;
    TxtColumns.Left(150);
    TxtColumns.Top(30);
    TxtColumns.Width(150);
    Prompt.Controls.Add(TxtColumns);

    ButtonOk := ButtonOk.Button;
    ButtonOk.Text('OK');
    ButtonOk.Left(50);
    ButtonOk.Top(100);
    ButtonOk.Width(100);
    ButtonOk.DialogResult := DailogResult.OK;
    Prompt.Controls.Add(ButtonOk);
    Prompt.AcceptButton := ButtonOk;

    ButtonCancel := ButtonCancel.Button;
    ButtonCancel.Text('Cancel');
    ButtonCancel.Left(200);
    ButtonCancel.Top(100);
    ButtonCancel.Width(100);
    ButtonCancel.DialogResult := DailogResult.Cancel;
    Prompt.Controls.Add(ButtonCancel);
    Prompt.AcceptButton := ButtonCancel;

    ResonCode := '1';
    IF (Prompt.ShowDialog.ToString() = DailogResult.OK.ToString()) THEN BEGIN
        //  IF TxtRows.Text <> '' THEN
        //    ResonCode := TxtRows.Text
        //  ELSE
        //     ERROR(CancelReasonErr);
        IF TxtColumns.Text <> '' THEN
            ReasonRemarks := TxtColumns.Text
        ELSE
            ERROR(CancelRemarksErr);
    END ELSE
        EXIT(FALSE);

    Prompt.Dispose;

    EXIT(TRUE);

end;*/

    local procedure GetMailId(EmailTxt: Text[80]) ReturnTxt: Text;
    begin
        //>>5002Fix 30Dec2020
        IF STRPOS(EmailTxt, ';') <> 0 THEN BEGIN
            ReturnTxt := CONVERTSTR(EmailTxt, ';', ',');
            ReturnTxt := SELECTSTR(1, ReturnTxt);
        END ELSE
            ReturnTxt := COPYSTR(EmailTxt, 1, 50);
        //<<5002Fix 30Dec2020
    end;

    local procedure "---E-INVB2C---"();
    begin
    end;

    procedure GenerateFormatForB2C(Variant: Variant);
    var
        SuppGSTIN: Code[15];
        SuppUPIID: Text;
        InvDate: Text[10];
        CompanyInfo: Record 79;
        PayeeBankAcc: Text[30];
        PayeeIFSCCode: Code[11];
        LocRec: Record Location;
        AssVal: Decimal;
        CgstVal: Decimal;
        SgstVal: Decimal;
        IgstVal: Decimal;
        CesVal: Decimal;
        StCesVal: Decimal;
        CesNonAdval: Decimal;
        Disc: Decimal;
        OthChrg: Decimal;
        TotInvVal: Decimal;
        RndOffAmt: Decimal;
        TotInvValFc: Decimal;
        PayeeBankACTxt: Label 'Payee''s Bank A/C';
        PayeeBankIFSCTxt: Label 'Payee''s Bank IFSC';
    begin
        //>>E-INVB2C >>
        // IF ISNULL(StringBuilder) THEN
        //   Initialize;

        CLEAR(CurrCode);
        CLEAR(CurrFactor);

        CompanyInfo.GET;
        PayeeBankAcc := CompanyInfo."Bank Account No.";
        PayeeIFSCCode := CompanyInfo."Payee Bank IFSC Code";

        IF IsInvoice THEN BEGIN
            DocumentNo := SalesInvoiceHeader."No.";
            CurrCode := SalesInvoiceHeader."Currency Code";
            CurrFactor := SalesInvoiceHeader."Currency Factor";
            SuppGSTIN := SalesInvoiceHeader."Location GST Reg. No.";
            InvDate := FORMAT(SalesInvoiceHeader."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>');
            LocRec.GET(SalesInvoiceHeader."Location Code");
        END ELSE BEGIN
            DocumentNo := SalesCrMemoHeader."No.";
            CurrCode := SalesCrMemoHeader."Currency Code";
            CurrFactor := SalesCrMemoHeader."Currency Factor";
            SuppGSTIN := SalesCrMemoHeader."Location GST Reg. No.";
            InvDate := FORMAT(SalesCrMemoHeader."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>');
            LocRec.GET(SalesCrMemoHeader."Location Code");
        END;
        SuppUPIID := LocRec."Supplier UPI ID";

        GetGSTVal(AssVal, CgstVal, SgstVal, IgstVal, CesVal, StCesVal, CesNonAdval, Disc, OthChrg, TotInvVal, TotInvValFc);

        //B2B>>
        JObjVerG.Add('Supplier GSTIN', SuppGSTIN);
        JObjVerG.Add('Supplier UPI ID', SuppUPIID);
        JObjVerG.Add('PayeeBankACTxt', PayeeBankIFSCTxt);
        JObjVerG.Add('PayeeBankIFSCTxt', PayeeBankIFSCTxt);
        JObjVerG.Add('Invoice number', DocumentNo);
        JObjVerG.Add('Invoice Date', InvDate);
        JObjVerG.Add('Total Invoice Value', TotInvVal);
        if CgstVal <> 0 then
            JObjVerG.Add('CgstVal', CgstVal)
        else
            JObjVerG.Add('CgstVal', JVOBJG.AsToken());
        if SgstVal <> 0 then
            JObjVerG.Add('SgstVal', SgstVal)
        else
            JObjVerG.Add('SgstVal', JVOBJG.AsToken());
        if IgstVal <> 0 then
            JObjVerG.Add('IgstVal', IgstVal)
        else
            JObjVerG.Add('IgstVal', JVOBJG.AsToken());
        if CesVal <> 0 then
            JObjVerG.Add('CesVal', CesVal)
        else
            JObjVerG.Add('CesVal', JVOBJG.AsToken());
        if StCesVal <> 0 then
            JObjVerG.Add('StCesVal', StCesVal)
        else
            JObjVerG.Add('StCesVal', StCesVal);
        if CesNonAdval <> 0 then
            JObjVerG.Add('CesNonAdval', CesNonAdval)
        else
            JObjVerG.Add('CesNonAdval', JVOBJG.AsToken());
        //B2B<<
    end;

    //B2BUPG1.0>> - Added due to missing of GST fields.
    local procedure GetGSTValueForLine(
        DocumentLineNo: Integer;
        var CGSTLineAmount: Decimal;
        var SGSTLineAmount: Decimal;
        var IGSTLineAmount: Decimal;
        var CESSLineAmount: Decimal)
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        CGSTLbl: Label 'CGST', Locked = true;
        SGSTLbl: label 'SGST', Locked = true;
        IGSTLbl: Label 'IGST', Locked = true;
        CESSLbl: Label 'CESS', Locked = true;
    begin
        CGSTLineAmount := 0;
        SGSTLineAmount := 0;
        IGSTLineAmount := 0;

        DetailedGSTLedgerEntry.SetRange("Document No.", DocumentNo);
        DetailedGSTLedgerEntry.SetRange("Document Line No.", DocumentLineNo);
        DetailedGSTLedgerEntry.SetRange("GST Component Code", CGSTLbl);
        if DetailedGSTLedgerEntry.FindSet() then
            repeat
                CGSTLineAmount += Abs(DetailedGSTLedgerEntry."GST Amount");
            until DetailedGSTLedgerEntry.Next() = 0;

        DetailedGSTLedgerEntry.SetRange("GST Component Code", SGSTLbl);
        if DetailedGSTLedgerEntry.FindSet() then
            repeat
                SGSTLineAmount += Abs(DetailedGSTLedgerEntry."GST Amount")
            until DetailedGSTLedgerEntry.Next() = 0;

        DetailedGSTLedgerEntry.SetRange("GST Component Code", IGSTLbl);
        if DetailedGSTLedgerEntry.FindSet() then
            repeat
                IGSTLineAmount += Abs(DetailedGSTLedgerEntry."GST Amount")
            until DetailedGSTLedgerEntry.Next() = 0;

        DetailedGSTLedgerEntry.SetRange("GST Component Code", CESSLbl);
        if DetailedGSTLedgerEntry.FindSet() then
            repeat
                CESSLineAmount += Abs(DetailedGSTLedgerEntry."GST Amount")
            until DetailedGSTLedgerEntry.Next() = 0;
    end;
    //B2BUPG1.0<<
    procedure GetRequestPath(var RequestPathLvar: Text)
    var
        myInt: Integer;
    begin
        RequestPathLvar := JsonRequestPath;
    end;

    procedure SetTransferShipmentHeader(TransferShipmentHeaderBuff: Record "Transfer Shipment Header");
    begin
        //EInvTrans>>
        TransferShipmentHeader := TransferShipmentHeaderBuff;
        TransferShipment := TRUE;
        //EInvTrans<<
    end;

    procedure GetNumberFilter() ReturnValue: Text
    var
        DefferedOrderSetup: Record 50007;
        NumberArr: array[5] of Code[20];
        i: Integer;
    begin
        IF IsInvoice THEN BEGIN
            IF SalesInvoiceHeader."Sales Type" = '' THEN
                EXIT('');
            DefferedOrderSetup.GET(SalesInvoiceHeader."Sales Type");
        END ELSE BEGIN
            IF SalesCrMemoHeader."Sales Type" = '' THEN
                EXIT('');
            DefferedOrderSetup.GET(SalesCrMemoHeader."Sales Type");
        END;

        NumberArr[1] := DefferedOrderSetup."Revenue Account Sales";
        NumberArr[2] := DefferedOrderSetup."Deffered Account Sales";
        NumberArr[3] := DefferedOrderSetup."Revenue Account Maintenance";
        NumberArr[4] := DefferedOrderSetup."Deffered Account Maintenance";
        NumberArr[5] := DefferedOrderSetup."Sales Account";

        FOR i := 1 TO 5 DO BEGIN
            IF NumberArr[i] <> '' THEN
                IF ReturnValue = '' THEN
                    ReturnValue := NumberArr[i]
                ELSE
                    ReturnValue += '&<>' + NumberArr[i];
        END;
    end;
    //B2BSaas Body>>
    procedure JSONFormat(var JsonFile: Text)
    begin
        JObjVerG.WriteTo(JsonFile);
    end;
    //B2BSaas Body<<
    procedure JSONcanFormat(var JsonFile: Text)
    begin
        JObJCancelG.WriteTo(JsonFile);
    end;

    local procedure ExportAsJson(FileName: Text[30]; var PathSaved: Text; JSONText: text);
    var
        TempFile: File;
        ToFile: Variant;
        NewStream: InStream;
        EInvoiceSetup: Record "E-Invoice Setup";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        FileMgt: Codeunit "File Management";
    begin
        FileName := DELCHR(FileName, '=', '/\-_*^@');
        ToFile := FileName + '.json';

        EInvoiceSetup.GET;
        PathSaved := EInvoiceSetup."JSON Request Path" + FileName + '.json';

        CLEAR(TempBlob);

        if FILE.Exists(PathSaved) then
            File.Erase(PathSaved);
        TempBlob.CREATEOUTSTREAM(OutStream, TEXTENCODING::UTF8);
        OutStream.WRITETEXT(JSONText);

        FileMgt.BLOBExportToServerFile(TempBlob, PathSaved);
        Clear(TempBlob);
        Clear(FileMgt);
    end;
}

