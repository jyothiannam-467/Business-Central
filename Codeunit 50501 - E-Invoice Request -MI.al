codeunit 50008 "E-Invoice Request -MI"
{
    // version E-INV,v1.03,5002Fix,FreeSupplyFix,EXPFIX,POSShipToGSTINFix,NonGst

    // 5002Fix
    // FreeSupplyFix
    // EXPFIX    Only for Invoice
    // NonGst


    trigger OnRun();
    begin
        // IF ISNULL(StringBuilder) THEN
        //   Initialize;

        IF IsInvoice THEN
            WITH SalesInvoiceHeader DO BEGIN
                IF "GST Customer Type" IN ["GST Customer Type"::Unregistered, "GST Customer Type"::" "]
                THEN
                    ERROR(UnRegCusrErr);

                DocumentNo := "No.";
                WriteFileHeader;
                WriteTransDtls;
                ReadDocDtls;
                ReadSellerDtls;
                ReadBuyerDtls;
                ReadDispDtls;
                ReadShipDtls;
                ReadExpDtls;
                ReadPayDtls;
                ReadRefDtls;
                ReadAddlDocDtls;
                ReadValDtls;
                ReadEwbDtls;
                ReadItemList;
            END
        ELSE
            WITH SalesCrMemoHeader DO BEGIN
                IF "GST Customer Type" IN ["GST Customer Type"::Unregistered, "GST Customer Type"::" "]
                THEN
                    ERROR(UnRegCusrErr);

                DocumentNo := "No.";
                WriteFileHeader;
                WriteTransDtls;
                ReadDocDtls;
                ReadSellerDtls;
                ReadBuyerDtls;
                ReadDispDtls;
                ReadShipDtls;
                ReadExpDtls;
                ReadPayDtls;
                ReadRefDtls;
                ReadAddlDocDtls;
                ReadValDtls;
                ReadEwbDtls;
                ReadItemList;
            END;

        IF DocumentNo <> '' THEN begin
            JSOAsstokenG.WriteTo(JSAccstokenTextG);
            ExportAsJson(DocumentNo + '_MI', JsonRequestPath, JSAccstokenTextG);
        end ELSE
            ERROR(RecIsEmptyErr);

        // GST Integration Log Start
        EInvoiceLog.INIT;
        IF IsInvoice THEN BEGIN
            EInvoiceLog."Document Type" := EInvoiceLog."Document Type"::Invoice;
            EInvoiceLog."Document No." := SalesInvoiceHeader."No.";
        END ELSE BEGIN
            EInvoiceLog."Document Type" := EInvoiceLog."Document Type"::"Credit Memo";
            EInvoiceLog."Document No." := SalesCrMemoHeader."No.";
        END;
        EInvoiceLog."Request Path" := JsonRequestPath;
        EInvoiceLog.INSERT(true);
        // GST Integration Log End
    end;

    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";

        //B2BSaas>>
        JSOAsstokenG: JsonObject;

        JSAccstokenTextG: Text;
        JSCancelTextG: Text;
        JSTranDtlsG: JsonObject;
        JSOExportG: JsonObject;
        JSOSellerDtlG: JsonObject;
        JVObjG: JsonValue;
        JSODocdtlsG: JsonObject;
        JSOEwayBillG: JsonObject;
        JSOShipDtlsG: JsonObject;
        JSoBuyerDtlsG: JsonObject;
        JSODispdtlsG: JsonObject;
        JSOItemLineG: JsonObject;
        JSOItemArryG: JsonArray;
        JSObBatchDtlaG: JsonObject;
        JSObjPayDtlsG: JsonObject;
        JSObjRefDtlsG: JsonObject;
        JSObjPrecDocDtlsG: JsonObject;
        JSArrayPreDtlsG: JsonArray;
        JObjContrDtlsG: JsonObject;
        JArrayContrDtlsG: JsonArray;
        JSODcoDtlsG: JsonObject;
        JSArryDocDtlsG: JsonArray;
        JOValDtlsG: JsonObject;
        JOCancelG: JsonObject;
        JOBJAcctoken: JsonObject;
        //B2BSaas<<

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
        //B2BUPGSERVICE1.0>> Service Orders
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        IsServiceInvoice: Boolean;
    //B2BUPGSERVICE1.0<< Service Orders

    local procedure WriteFileHeader();
    var
        EInvoiceSetup: Record "E-Invoice Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        IF IsInvoice THEN
            SalesInvoiceHeader.GET(DocumentNo)
        ELSE
            SalesCrMemoHeader.GET(DocumentNo);
        EInvoiceSetup.GET;
        /*
        JsonTextWriter.WriteStartObject;
        JsonTextWriter.WritePropertyName('access_token');
        JsonTextWriter.WriteValue(EInvoiceSetup."MI Access Token" + EInvoiceSetup."MI Access Token 2");
        JsonTextWriter.WritePropertyName('user_gstin');
        //JsonTextWriter.WriteValue('09AAAPG7885R002');//need to change - EInvoiceSetup.GSTIN
        IF IsInvoice THEN
            JsonTextWriter.WriteValue(SalesInvoiceHeader."Location GST Reg. No.")
        ELSE
            JsonTextWriter.WriteValue(SalesCrMemoHeader."Location GST Reg. No.");
        JsonTextWriter.WritePropertyName('data_source');
        JsonTextWriter.WriteValue('erp');
        */
        JSOAsstokenG.Add('access_token', EInvoiceSetup."MI Access Token" + EInvoiceSetup."MI Access Token 2");
        if IsInvoice then
            JSOAsstokenG.Add('user_gstin', SalesInvoiceHeader."Location GST Reg. No.")
        else
            JSOAsstokenG.Add('user_gstin', SalesCrMemoHeader."Location GST Reg. No.");
        JSOAsstokenG.Add('data_source', 'erp');
    end;

    local procedure WriteTransDtls();
    var
        SupTyp: Text[10];
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
        END ELSE BEGIN
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
        END;
        /*
        JsonTextWriter.WritePropertyName('transaction_details');
        JsonTextWriter.WriteStartObject;

        JsonTextWriter.WritePropertyName('supply_type');
        JsonTextWriter.WriteValue(SupTyp);
        JsonTextWriter.WritePropertyName('charge_type');//Reverse charge
        JsonTextWriter.WriteValue('N');
        JsonTextWriter.WritePropertyName('igst_on_intra');
        JsonTextWriter.WriteValue('N');
        JsonTextWriter.WritePropertyName('ecommerce_gstin');
        JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WriteEndObject;
        */
        JSTranDtlsG.Add('supply_type', SupTyp);
        JSTranDtlsG.Add('charge_type', 'N');
        JSTranDtlsG.Add('igst_on_intra', 'N');
        JSTranDtlsG.Add('ecommerce_gstin', JVObjG.AsToken());
        JSOAsstokenG.Add('transaction_details', JSTranDtlsG);
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
        END ELSE BEGIN
            Typ := 'CRN';
            Dt := FORMAT(SalesCrMemoHeader."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>');
        END;

        WriteDocDtls(Typ, COPYSTR(DocumentNo, 1, 16), Dt);
    end;

    local procedure WriteDocDtls(Typ: Text[3]; No: Text[16]; Dt: Text[10]);
    begin
        /*
        JsonTextWriter.WritePropertyName('document_details');
        JsonTextWriter.WriteStartObject;

        JsonTextWriter.WritePropertyName('document_type');
        JsonTextWriter.WriteValue(Typ);
        JsonTextWriter.WritePropertyName('document_number');
        JsonTextWriter.WriteValue(No);
        JsonTextWriter.WritePropertyName('document_date');
        JsonTextWriter.WriteValue(Dt);
        JsonTextWriter.WriteEndObject;
        */
        JSODocdtlsG.Add('document_type', Typ);
        JSODocdtlsG.Add('document_number', No);
        JSODocdtlsG.Add('document_date', Dt);
        JSOAsstokenG.Add('document_details', JSODocdtlsG);
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
        ExportDuty: Decimal;
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
            END;

        IF (ShipBNo = '') AND (ShipBDt = '') AND (Port = '') AND (ForCur = '') THEN BEGIN
            //  JsonTextWriter.WritePropertyName('export_details');
            // JsonTextWriter.WriteValue(GlobalNULL);
            JSOAsstokenG.Add('export_details', JVObjG.AsToken());
        END ELSE
            WriteExpDtls(ShipBNo, ShipBDt, Port, RefClm, ForCur, CntCode, ExportDuty);
    end;

    local procedure WriteExpDtls(ShipBNo: Text[16]; ShipBDt: Text[10]; Port: Text[10]; RefClm: Text[1]; ForCur: Text[3]; CntCode: Text[2]; ExportDuty: Decimal);
    begin
        /*
        JsonTextWriter.WritePropertyName('export_details');
        JsonTextWriter.WriteStartObject;

        JsonTextWriter.WritePropertyName('ship_bill_number');
        IF ShipBNo <> '' THEN
            JsonTextWriter.WriteValue(ShipBNo)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('ship_bill_date');
        IF ShipBDt <> '' THEN
            JsonTextWriter.WriteValue(ShipBDt)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('country_code');
        IF CntCode <> '' THEN
            JsonTextWriter.WriteValue(CntCode)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('foreign_currency');
        IF ForCur <> '' THEN
            JsonTextWriter.WriteValue(ForCur)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('refund_claim');
        IF RefClm <> '' THEN
            JsonTextWriter.WriteValue(RefClm)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('port_code');
        IF Port <> '' THEN
            JsonTextWriter.WriteValue(Port)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('export_duty');
        IF ExportDuty <> 0 THEN
            JsonTextWriter.WriteValue(ExportDuty)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);

        JsonTextWriter.WriteEndObject;
        */
        if ShipBNo <> '' then
            JSOExportG.Add('ShipBNo', ShipBNo)
        else
            JSOExportG.Add('ShipBNo', JVObjG.AsToken());
        if ShipBDt <> '' then
            JSOExportG.Add('ShipBDt', ShipBDt)
        else
            JSOExportG.Add('ShipBDt', JVObjG.AsToken());
        if CntCode <> '' then
            JSOExportG.Add('country_code', CntCode)
        else
            JSOExportG.Add('country_code', JVObjG.AsToken());
        if ForCur <> '' then
            JSOExportG.Add('foreign_currency', ForCur)
        else
            JSOExportG.Add('foreign_currency', JVObjG.AsToken());
        if RefClm <> '' then
            JSOExportG.Add('refund_claim', RefClm)
        else
            JSOExportG.Add('refund_claim', JVObjG.AsToken());
        if Port <> '' then
            JSOExportG.Add('port_code', Port)
        else
            JSOExportG.Add('port_code', JVObjG.AsToken());
        if ExportDuty <> 0 then
            JSOExportG.Add('export_duty', ExportDuty)
        else
            JSOExportG.Add('export_duty', JVObjG.AsToken());
        JSOAsstokenG.Add('export_details', JSOExportG);

    end;

    local procedure ReadEwbDtls();
    var
        TransId: Text[15];
        TransName: Text[100];
        TransMode: Text[1];
        Distance: Text[4];
        TransDocNo: Text[15];
        TransDocDt: Text[10];
        VehNo: Text[20];
        VehType: Text[1];
        TransportMethod: Record 259;
        DistanceTxt: Text;
    begin
        IF IsInvoice THEN
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
                IF "Distance (Km)" <> 0 THEN BEGIN
                    DistanceTxt := DELCHR(FORMAT(ROUND("Distance (Km)", 1, '=')), '=', ',');

                    IF STRLEN(DistanceTxt) > 4 THEN
                        Distance := COPYSTR(DistanceTxt, 1, 4)
                    ELSE
                        Distance := DistanceTxt;
                END ELSE
                    Distance := '';
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
        ELSE
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
                IF "Distance (Km)" <> 0 THEN BEGIN
                    DistanceTxt := DELCHR(FORMAT(ROUND("Distance (Km)", 1, '=')), '=', ',');

                    IF STRLEN(DistanceTxt) > 4 THEN
                        Distance := COPYSTR(DistanceTxt, 1, 4)
                    ELSE
                        Distance := DistanceTxt;
                END ELSE
                    Distance := '';
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

        IF (TransId = '') AND (TransName = '') AND (TransMode = '') AND (Distance = '') AND (TransDocNo = '') AND (TransDocDt = '') AND
          (VehNo = '') AND (VehType = '')
        THEN BEGIN
            // JsonTextWriter.WritePropertyName('ewaybill_details');
            //JsonTextWriter.WriteValue(GlobalNULL);
            JSOAsstokenG.Add('ewaybill_details', JVObjG.AsToken());
        END ELSE
            WriteEwbDtls(TransId, TransName, TransMode, Distance, TransDocNo, TransDocDt, VehNo, VehType);
    end;

    local procedure WriteEwbDtls(TransId: Text[15]; TransName: Text[100]; TransMode: Text[1]; Distance: Text[4]; TransDocNo: Text[15]; TransDocDt: Text[10]; VehNo: Text[20]; VehType: Text[1]);
    begin
        /*
        JsonTextWriter.WritePropertyName('ewaybill_details');
        JsonTextWriter.WriteStartObject;

        JsonTextWriter.WritePropertyName('transporter_id');
        IF TransId <> '' THEN
            JsonTextWriter.WriteValue(TransId)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('transporter_name');
        IF TransName <> '' THEN
            JsonTextWriter.WriteValue(TransName)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('transportation_mode');
        IF TransMode <> '' THEN
            JsonTextWriter.WriteValue(TransMode)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('transportation_distance');
        IF Distance <> '' THEN
            JsonTextWriter.WriteValue(Distance)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('transporter_document_number');
        IF TransDocNo <> '' THEN
            JsonTextWriter.WriteValue(TransDocNo)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('transporter_document_date');
        IF TransDocDt <> '' THEN
            JsonTextWriter.WriteValue(TransDocDt)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('vehicle_number');
        IF VehNo <> '' THEN
            JsonTextWriter.WriteValue(VehNo)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('vehicle_type');
        IF VehType <> '' THEN
            JsonTextWriter.WriteValue(VehType)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WriteEndObject;
        */
        if TransId <> '' then
            JSOEwayBillG.Add('transporter_id', TransId)
        else
            JSOEwayBillG.Add('transporter_id', JVObjG.AsToken());
        if TransName <> '' then
            JSOEwayBillG.Add('transporter_name', TransName)
        else
            JSOEwayBillG.Add('transporter_name', JVObjG.AsToken());
        if TransMode <> '' then
            JSOEwayBillG.Add('transportation_mode', TransMode)
        else
            JSOEwayBillG.Add('transportation_mode', JVObjG.AsToken());
        if Distance <> '' then
            JSOEwayBillG.Add('transportation_distance', Distance)
        else
            JSOEwayBillG.Add('transportation_distance', JVObjG.AsToken());
        if TransDocNo <> '' then
            JSOEwayBillG.Add('transporter_document_number', TransDocNo)
        else
            JSOEwayBillG.Add('transporter_document_number', JVObjG.AsToken());
        if TransDocDt <> '' then
            JSOEwayBillG.Add('transporter_document_date', TransDocDt)
        else
            JSOEwayBillG.Add('transporter_document_date', JVObjG.AsToken());
        if VehNo <> '' then
            JSOEwayBillG.Add('vehicle_number', VehNo)
        else
            JSOEwayBillG.Add('vehicle_number', JVObjG.AsToken());
        if VehType <> '' then
            JSOEwayBillG.Add('vehicle_type', VehType)
        else
            JSOEwayBillG.Add('vehicle_type', JVObjG.AsToken());
        JSOAsstokenG.Add('ewaybill_details', JSOEwayBillG);

    end;

    local procedure ReadSellerDtls();
    var
        CompanyInformationBuff: Record 79;
        LocationBuff: Record Location;
        StateBuff: Record State;
        Gstin: Text[15];
        LglNm: Text[100];
        TrdNm: Text[100];
        Add1: Text[60];
        Add2: Text[60];
        Loc: Text[60];
        Pin: Text[6];
        StateNm: Text[60];
        Ph: Text[10];
        Em: Text[50];
    begin
        IF IsInvoice THEN
            WITH SalesInvoiceHeader DO BEGIN
                LocationBuff.GET("Location Code");
                //Gstin := LocationBuff."GST Registration No.";//2016CU19
                //Gstin := '09AAAPG7885R002';//"Location GST Reg. No.";
                Gstin := "Location GST Reg. No.";//v1.03
                CompanyInformationBuff.GET;
                LglNm := CompanyInformationBuff.Name;
                TrdNm := CompanyInformationBuff.Name;
                Add1 := LocationBuff.Address;
                Add2 := LocationBuff."Address 2";
                Loc := LocationBuff.Name;
                Pin := COPYSTR(LocationBuff."Post Code", 1, 6);
                StateBuff.GET(LocationBuff."State Code");
                //StateNm := StateBuff.Code;
                StateNm := StateBuff."State Code (GST Reg. No.)";//v1.03
                Ph := COPYSTR(LocationBuff."Phone No.", 1, 10);
                Em := GetMailId(LocationBuff."E-Mail");//5002Fix
            END
        ELSE
            WITH SalesCrMemoHeader DO BEGIN
                LocationBuff.GET("Location Code");
                //Gstin := LocationBuff."GST Registration No.";//2016CU19
                //Gstin := '09AAAPG7885R002';//"Location GST Reg. No.";
                Gstin := "Location GST Reg. No.";
                CompanyInformationBuff.GET;
                LglNm := CompanyInformationBuff.Name;
                TrdNm := CompanyInformationBuff.Name;
                Add1 := LocationBuff.Address;
                Add2 := LocationBuff."Address 2";
                Loc := LocationBuff.Name;
                Pin := COPYSTR(LocationBuff."Post Code", 1, 6);
                StateBuff.GET(LocationBuff."State Code");
                //StateNm := StateBuff.Description;
                StateNm := StateBuff."State Code (GST Reg. No.)";//v1.03
                Ph := COPYSTR(LocationBuff."Phone No.", 1, 10);
                Em := GetMailId(LocationBuff."E-Mail");//5002Fix
            END;

        WriteSellerDtls(Gstin, LglNm, TrdNm, Add1, Add2, Loc, Pin, StateNm, Ph, Em);
    end;

    local procedure WriteSellerDtls(Gstin: Text[15]; LglNm: Text[100]; TrdNm: Text[100]; Add1: Text[60]; Add2: Text[60]; Loc: Text[60]; Pin: Text[6]; StateNm: Text[60]; Ph: Text[10]; Em: Text[50]);
    begin
        /*
        JsonTextWriter.WritePropertyName('seller_details');
        JsonTextWriter.WriteStartObject;

        JsonTextWriter.WritePropertyName('gstin');
        IF Gstin <> '' THEN
            JsonTextWriter.WriteValue(Gstin)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('legal_name');
        IF LglNm <> '' THEN
            JsonTextWriter.WriteValue(LglNm)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('trade_name');
        IF TrdNm <> '' THEN
            JsonTextWriter.WriteValue(TrdNm)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('address1');
        IF Add1 <> '' THEN
            JsonTextWriter.WriteValue(Add1)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('address2');
        IF Add2 <> '' THEN
            JsonTextWriter.WriteValue(Add2)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('location');
        IF Loc <> '' THEN
            JsonTextWriter.WriteValue(Loc)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('pincode');
        IF Pin <> '' THEN
            JsonTextWriter.WriteValue(Pin)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('state_code');
        IF StateNm <> '' THEN
            JsonTextWriter.WriteValue(StateNm)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('phone_number');
        IF Ph <> '' THEN
            JsonTextWriter.WriteValue(Ph)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('email');
        IF Em <> '' THEN
            JsonTextWriter.WriteValue(Em)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WriteEndObject;
        */
        if Gstin <> '' then
            JSOSellerDtlG.Add('gstin', Gstin)
        else
            JSOSellerDtlG.Add('gstin', JVObjG.AsToken());
        if LglNm <> '' then
            JSOSellerDtlG.Add('legal_name', LglNm)
        else
            JSOSellerDtlG.Add('legal_name', JVObjG.AsToken());
        if TrdNm <> '' then
            JSOSellerDtlG.Add('trade_name', TrdNm)
        else
            JSOSellerDtlG.Add('trade_name', JVObjG.AsToken());
        if Add1 <> '' then
            JSOSellerDtlG.Add('address1', Add1)
        else
            JSOSellerDtlG.Add('address1', JVObjG.AsToken());
        if Add2 <> '' then
            JSOSellerDtlG.Add('address2', Add2)
        else
            JSOSellerDtlG.Add('address2', JVObjG.AsToken());
        if Loc <> '' then
            JSOSellerDtlG.Add('location', Loc)
        else
            JSOSellerDtlG.Add('location', JVObjG.AsToken());
        if Pin <> '' then
            JSOSellerDtlG.Add('pincode', Pin)
        else
            JSOSellerDtlG.Add('pincode', JVObjG.AsToken());
        if StateNm <> '' then
            JSOSellerDtlG.Add('state_code', StateNm)
        else
            JSOSellerDtlG.Add('state_code', JVObjG.AsToken());
        if Ph <> '' then
            JSOSellerDtlG.Add('phone_number', Ph)
        else
            JSOSellerDtlG.Add('phone_number', JVObjG.AsToken());
        if Em <> '' then
            JSOSellerDtlG.Add('email', Em)
        else
            JSOSellerDtlG.Add('email', JVObjG.AsToken());
        JSOAsstokenG.Add('seller_details', JSOSellerDtlG);


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
        Addr1: Text[60];
        Addr2: Text[60];
        Loc: Text[60];
        Pin: Text[6];
        Stcd: Code[2];
        Ph: Text[10];
        Em: Text[50];
        Customer: Record Customer;
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
                            //RtnOrdFix >>
                            //StateBuff.GET("GST Ship-to State Code");
                            StateBuff.GET(ShipToAddr.State);
                            //RtnOrdFix <<
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
                            //RtnOrdFix >>
                            //StateBuff.GET("GST Ship-to State Code");
                            StateBuff.GET(ShipToAddr.State);
                            //RtnOrdFix <<
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
            END;
        //<< POSShipToGSTINFix
        WriteBuyerDtls(Gstin, LglNm, TrdNm, Pos, Addr1, Addr2, Loc, Pin, Stcd, Ph, Em);
    end;

    local procedure WriteBuyerDtls(Gstin: Text[15]; LglNm: Text[100]; TrdNm: Text[100]; Pos: Text[2]; Addr1: Text[60]; Addr2: Text[60]; Loc: Text[60]; Pin: Text[6]; State: Text[60]; Ph: Text[10]; Em: Text[50]);
    begin
        /*
        JsonTextWriter.WritePropertyName('buyer_details');
        JsonTextWriter.WriteStartObject;

        JsonTextWriter.WritePropertyName('gstin');
        IF Gstin <> '' THEN
            JsonTextWriter.WriteValue(Gstin)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('legal_name');
        IF LglNm <> '' THEN
            JsonTextWriter.WriteValue(LglNm)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('trade_name');
        IF TrdNm <> '' THEN
            JsonTextWriter.WriteValue(TrdNm)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('address1');
        IF Addr1 <> '' THEN
            JsonTextWriter.WriteValue(Addr1)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('address2');
        IF Addr2 <> '' THEN
            JsonTextWriter.WriteValue(Addr2)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('location');
        IF Loc <> '' THEN
            JsonTextWriter.WriteValue(Loc)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('pincode');
        IF Pin <> '' THEN
            JsonTextWriter.WriteValue(Pin)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('place_of_supply');
        IF Pos <> '' THEN
            JsonTextWriter.WriteValue(Pos)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('state_code');
        IF State <> '' THEN
            JsonTextWriter.WriteValue(State)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('phone_number');
        IF Ph <> '' THEN
            JsonTextWriter.WriteValue(Ph)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('email');
        IF Em <> '' THEN
            JsonTextWriter.WriteValue(Em)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WriteEndObject;
        */
        if Gstin <> '' then
            JSoBuyerDtlsG.Add('gstin', Gstin)
        else
            JSoBuyerDtlsG.Add('gstin', JVObjG.AsToken());
        if LglNm <> '' then
            JSoBuyerDtlsG.Add('legal_name', LglNm)
        else
            JSoBuyerDtlsG.Add('legal_name', JVObjG.AsToken());
        if TrdNm <> '' then
            JSoBuyerDtlsG.Add('trade_name', TrdNm)
        else
            JSoBuyerDtlsG.Add('trade_name', JVObjG.AsToken());
        if Addr1 <> '' then
            JSoBuyerDtlsG.Add('address1', Addr1)
        else
            JSoBuyerDtlsG.Add('address1', JVObjG.AsToken());
        if Addr2 <> '' then
            JSoBuyerDtlsG.Add('address2', Addr2)
        else
            JSoBuyerDtlsG.Add('address2', JVObjG.AsToken());
        if Loc <> '' then
            JSoBuyerDtlsG.Add('location', Loc)
        else
            JSoBuyerDtlsG.Add('location', JVObjG.AsToken());
        if Pin <> '' then
            JSoBuyerDtlsG.Add('pincode', Pin)
        else
            JSoBuyerDtlsG.Add('pincode', JVObjG.AsToken());
        if Pos <> '' then
            JSoBuyerDtlsG.Add('place_of_supply', Pos)
        else
            JSoBuyerDtlsG.Add('place_of_supply', JVObjG.AsToken());
        if State <> '' then
            JSoBuyerDtlsG.Add('state_code', State)
        else
            JSoBuyerDtlsG.Add('state_code', JVObjG.AsToken());
        if Ph <> '' then
            JSoBuyerDtlsG.Add('phone_number', Ph)
        else
            JSoBuyerDtlsG.Add('phone_number', JVObjG.AsToken());
        if Em <> '' then
            JSoBuyerDtlsG.Add('email', Em)
        else
            JSoBuyerDtlsG.Add('email', JVObjG.AsToken());
        JSOAsstokenG.Add('buyer_details', JSoBuyerDtlsG);

    end;

    local procedure ReadDispDtls();
    var
        CompanyInformationBuff: Record 79;
        LocationBuff: Record Location;
        StateBuff: Record State;
        Nm: Text[100];
        Add1: Text[60];
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
            WITH SalesCrMemoHeader DO BEGIN
                CompanyInformationBuff.GET;
                Nm := CompanyInformationBuff.Name;
                LocationBuff.GET("Location Code");
                Add1 := LocationBuff.Address;
                Add2 := LocationBuff."Address 2";
                Loc := LocationBuff.Name;
                Pin := COPYSTR(LocationBuff."Post Code", 1, 6);
                StateBuff.GET(LocationBuff."State Code");
                Stcd := StateBuff."State Code (GST Reg. No.)";
            END;

        WriteDispDtls(Nm, Add1, Add2, Loc, Pin, Stcd);
    end;

    local procedure WriteDispDtls(Nm: Text[100]; Add1: Text[60]; Add2: Text[60]; Loc: Text[60]; Pin: Text[6]; Stcd: Text[2]);
    begin
        /*
        JsonTextWriter.WritePropertyName('dispatch_details');
        JsonTextWriter.WriteStartObject;

        JsonTextWriter.WritePropertyName('company_name');
        IF Nm <> '' THEN
            JsonTextWriter.WriteValue(Nm)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('address1');
        IF Add1 <> '' THEN
            JsonTextWriter.WriteValue(Add1)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('address2');
        IF Add2 <> '' THEN
            JsonTextWriter.WriteValue(Add2)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('location');
        IF Loc <> '' THEN
            JsonTextWriter.WriteValue(Loc)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('pincode');
        IF Pin <> '' THEN
            JsonTextWriter.WriteValue(Pin)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('state_code');
        IF Stcd <> '' THEN
            JsonTextWriter.WriteValue(Stcd)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WriteEndObject;
        */
        if Nm <> '' then
            JSODispdtlsG.Add('company_name', Nm)
        else
            JSODispdtlsG.Add('company_name', JVObjG.AsToken());
        if Add1 <> '' then
            JSODispdtlsG.Add('address1', Add1)
        else
            JSODispdtlsG.Add('address1', JVObjG.AsToken());
        if Add2 <> '' then
            JSODispdtlsG.Add('address2', Add2)
        else
            JSODispdtlsG.Add('address2', JVObjG.AsToken());
        if Loc <> '' then
            JSODispdtlsG.Add('location', Loc)
        else
            JSODispdtlsG.Add('location', JVObjG.AsToken());
        if Pin <> '' then
            JSODispdtlsG.Add('pincode', Pin)
        else
            JSODispdtlsG.Add('pincode', JVObjG.AsToken());
        if Stcd <> '' then
            JSODispdtlsG.Add('state_code', Stcd)
        else
            JSODispdtlsG.Add('state_code', JVObjG.AsToken());
        JSOAsstokenG.Add('dispatch_details', JSODispdtlsG);

    end;

    local procedure ReadShipDtls();
    var
        ShipToAddr: Record "Ship-to Address";
        StateBuff: Record State;
        Gstin: Text[15];
        LglNm: Text[100];
        TrdNm: Text[100];
        Addr1: Text[60];
        Addr2: Text[60];
        Loc: Text[60];
        Pin: Text[6];
        Stcd: Text[2];
        Ph: Text[10];
        Em: Text[50];
        Customer: Record Customer;
    begin
        IF IsInvoice THEN BEGIN
            WITH SalesInvoiceHeader DO BEGIN
                IF ShipToAddr.GET("Sell-to Customer No.", "Ship-to Code") THEN BEGIN
                    LglNm := "Ship-to Name";
                    TrdNm := "Ship-to Name";
                    Addr1 := "Ship-to Address";
                    Addr2 := "Ship-to Address 2";
                    Loc := "Ship-to City";
                    IF "GST Customer Type" <> "GST Customer Type"::Export THEN BEGIN
                        //Gstin := '05AAAPG7885R002';//ShipToAddr."GST Registration No.";
                        Gstin := ShipToAddr."GST Registration No.";
                        //RtnOrdFix >>
                        //StateBuff.GET("GST Ship-to State Code");
                        StateBuff.GET(ShipToAddr.State);
                        //RtnOrdFix <<
                        Stcd := StateBuff."State Code (GST Reg. No.)";
                        Pin := COPYSTR("Ship-to Post Code", 1, 6);
                    END ELSE BEGIN
                        Gstin := '';
                        Stcd := '96';
                        Pin := '999999';
                    END;
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
                          //Gstin := '05AAAPG7885R002';//"Customer GST Reg. No.";
                        Gstin := "Customer GST Reg. No.";
                        StateBuff.GET("GST Bill-to State Code");
                        Stcd := StateBuff."State Code (GST Reg. No.)";
                        Pin := COPYSTR("Bill-to Post Code", 1, 6);
                    END ELSE BEGIN
                        Gstin := '';
                        Stcd := '96';
                        Pin := '999999';
                    END;
                END;
            END;
            WriteShipDtls(Gstin, LglNm, TrdNm, Addr1, Addr2, Loc, Pin, Stcd);
        END ELSE BEGIN
            WITH SalesCrMemoHeader DO BEGIN
                IF ShipToAddr.GET("Sell-to Customer No.", "Ship-to Code") THEN BEGIN
                    LglNm := "Ship-to Name";
                    TrdNm := "Ship-to Name";
                    Addr1 := "Ship-to Address";
                    Addr2 := "Ship-to Address 2";
                    Loc := "Ship-to City";
                    Pin := COPYSTR("Ship-to Post Code", 1, 6);
                    IF "GST Customer Type" <> "GST Customer Type"::Export THEN BEGIN
                        //Gstin := '02AMBPG7773M002';//ShipToAddr."GST Registration No.";
                        Gstin := ShipToAddr."GST Registration No.";
                        //RtnOrdFix >>
                        //StateBuff.GET("GST Ship-to State Code");
                        StateBuff.GET(ShipToAddr.State);
                        //RtnOrdFix <<
                        Stcd := StateBuff."State Code (GST Reg. No.)";
                        Pin := COPYSTR("Ship-to Post Code", 1, 6);
                    END ELSE BEGIN
                        Gstin := '';
                        Stcd := '96';
                        Pin := '999999';
                    END;
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
                          //Gstin := '02AMBPG7773M002';//"Customer GST Reg. No.";
                        Gstin := "Customer GST Reg. No.";
                        StateBuff.GET("GST Bill-to State Code");
                        Stcd := StateBuff."State Code (GST Reg. No.)";
                        Pin := COPYSTR("Bill-to Post Code", 1, 6);
                    END ELSE BEGIN
                        Gstin := '';
                        Stcd := '96';
                        Pin := '999999';
                    END;
                END;
            END;
            WriteShipDtls(Gstin, LglNm, TrdNm, Addr1, Addr2, Loc, Pin, Stcd);
        END;

    end;

    local procedure WriteShipDtls(Gstin: Text[15]; LglNm: Text[100]; TrdNm: Text[100]; Addr1: Text[60]; Addr2: Text[60]; Loc: Text[60]; Pin: Text[6]; Stcd: Text[2]);
    begin
        /*
        JsonTextWriter.WritePropertyName('ship_details');
        JsonTextWriter.WriteStartObject;

        JsonTextWriter.WritePropertyName('gstin');
        IF Gstin <> '' THEN
            JsonTextWriter.WriteValue(Gstin)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('legal_name');
        IF LglNm <> '' THEN
            JsonTextWriter.WriteValue(LglNm)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('trade_name');
        IF TrdNm <> '' THEN
            JsonTextWriter.WriteValue(TrdNm)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('address1');
        IF Addr1 <> '' THEN
            JsonTextWriter.WriteValue(Addr1)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('address2');
        IF Addr2 <> '' THEN
            JsonTextWriter.WriteValue(Addr2)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('location');
        IF Loc <> '' THEN
            JsonTextWriter.WriteValue(Loc)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('pincode');
        IF Pin <> '' THEN
            JsonTextWriter.WriteValue(Pin)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('state_code');
        IF Stcd <> '' THEN
            JsonTextWriter.WriteValue(Stcd)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WriteEndObject;
        */
        if Gstin <> '' then
            JSOShipDtlsG.Add('gstin', Gstin)
        else
            JSOShipDtlsG.Add('gstin', JVObjG.AsToken());
        if LglNm <> '' then
            JSOShipDtlsG.Add('legal_name', LglNm)
        else
            JSOShipDtlsG.Add('legal_name', JVObjG.AsToken());
        if TrdNm <> '' then
            JSOShipDtlsG.Add('trade_name', TrdNm)
        else
            JSOShipDtlsG.Add('trade_name', JVObjG.AsToken());
        if Addr1 <> '' then
            JSOShipDtlsG.Add('address1', Addr1)
        else
            JSOShipDtlsG.Add('address1', JVObjG.AsToken());
        if Addr2 <> '' then
            JSOShipDtlsG.Add('address2', Addr2)
        else
            JSOShipDtlsG.Add('address2', Addr2);
        if Loc <> '' then
            JSOShipDtlsG.Add('location', Loc)
        else
            JSOShipDtlsG.Add('location', JVObjG.AsToken());
        if Pin <> '' then
            JSOShipDtlsG.Add('pincode', Pin)
        else
            JSOShipDtlsG.Add('pincode', JVObjG.AsToken());
        if Stcd <> '' then
            JSOShipDtlsG.Add('state_code', Stcd)
        else
            JSOShipDtlsG.Add('state_code', JVObjG.AsToken());
        JSOAsstokenG.Add('ship_details', JSOShipDtlsG);


    end;

    local procedure ReadItemList();
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SlNo: Integer;
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
                // JsonTextWriter.WritePropertyName('item_list');
                //JsonTextWriter.WriteStartArray;
                REPEAT
                    SlNo += 1;
                    WriteItem(SalesInvoiceLine, SlNo, JSOItemLineG);
                    JSOItemArryG.Add(JSOItemLineG);
                UNTIL SalesInvoiceLine.NEXT = 0;
                JSOAsstokenG.Add('item_list', JSOItemArryG);
                //JsonTextWriter.WriteEndArray;
            END;
        END ELSE BEGIN
            SalesCrMemoLine.SETRANGE("Document No.", DocumentNo);
            //B2BUPG1.0>>
            //SalesCrMemoLine.SETFILTER("No.", '<>%1&<>%2&<>%3', '', GetInvRoundingAcc, GetGSTRoundingAcc);
            SalesCrMemoLine.SETFILTER("No.", NumberFilter);
            //B2BUPG1.0<<
            SalesCrMemoLine.SETFILTER(Quantity, '<>%1', 0);
            IF SalesCrMemoLine.FINDSET THEN BEGIN
                IF SalesCrMemoLine.COUNT > 1000 THEN
                    ERROR(SalesLinesErr, SalesCrMemoLine.COUNT);
                //  JsonTextWriter.WritePropertyName('item_list');
                //JsonTextWriter.WriteStartArray;
                REPEAT
                    SlNo += 1;
                    WriteItem(SalesCrMemoLine, SlNo, JSOItemLineG);
                    JSOItemArryG.Add(JSOItemLineG);
                UNTIL SalesCrMemoLine.NEXT = 0;
                JSOAsstokenG.Add('item_list', JSOItemArryG);
                // JsonTextWriter.WriteEndArray;
            END;
        END;
    end;

    local procedure WriteItem(Variant: Variant; SlNo: Integer; var JSOItemLineL: JsonObject);
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
        BarCode: Text[30];
        Item: Record 27;
        LotExist: Boolean;
        LineNo: Integer;
        FreeQty: Decimal;
        PreTaxVal: Decimal;
        OrdLineRef: Integer;
        OrgCntry: Code[2];
        PrdSlNo: Code[20];
        UOM: Record "Unit of Measure";
        CurrExchRate: Record 330;
        TotGSTAmt: Decimal;
        SlNoL: Text;
        QTYL: Text;
        FreeQtyL: Text;
    begin
        RecRef.GETTABLE(Variant);
        CASE RecRef.NUMBER OF
            113:
                SalesInvoiceLine := Variant;
            115:
                SalesCrMemoLine := Variant;
        END;

        IF IsInvoice THEN BEGIN
            IF SalesInvoiceLine."GST Group Type" = SalesInvoiceLine."GST Group Type"::Service THEN
                IsServc := 'Y'
            ELSE
                IsServc := 'N';
            PrdDesc := SalesInvoiceLine.Description + SalesInvoiceLine."Description 2";
            HsnCd := SalesInvoiceLine."HSN/SAC Code";
            //>>v1.03
            BarCode := '';
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
            //B2BUPG1.0>> - Comented due to free supply has no solution.
            /*IF SalesInvoiceLine."Free Supply" THEN BEGIN
                Qty := 0;
                FreeQty := SalesInvoiceLine.Quantity;
                AssAmt := 0;
            END ELSE BEGIN*/
            //B2BUPG1.0<<
            //Qty := SalesInvoiceLine.Quantity;
            FreeQty := 0;
            IF SalesInvoiceLine."GST Assessable Value (LCY)" <> 0 THEN
                AssAmt := SalesInvoiceLine."GST Assessable Value (LCY)"
            //NonGst >>
            ELSE
                AssAmt := SalesInvoiceLine.Amount; //B2BUPG1.0
            /*IF SalesInvoiceLine."GST Base Amount" <> 0 THEN
                AssAmt := SalesInvoiceLine."GST Base Amount"
            ELSE
                AssAmt := SalesInvoiceLine."Line Amount" + SalesInvoiceLine."Inv. Discount Amount";*/
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
            //TotItemVal := SalesInvoiceLine."Amount Including Tax" + SalesInvoiceLine."Total GST Amount"; //B2BUPG1.0
            TotItemVal := SalesInvoiceLine."Amount Including VAT" + TotGSTAmt;
            //B2BUPG1.0<<

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
        END ELSE BEGIN
            IF SalesCrMemoLine."GST Group Type" = SalesCrMemoLine."GST Group Type"::Service THEN
                IsServc := 'Y'
            ELSE
                IsServc := 'N';
            PrdDesc := SalesCrMemoLine.Description + SalesCrMemoLine."Description 2";
            HsnCd := SalesCrMemoLine."HSN/SAC Code";
            //>>v1.03
            BarCode := '';
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
            Qty := SalesCrMemoLine.Quantity;
            FreeQty := 0;
            IF SalesCrMemoLine."GST Assessable Value (LCY)" <> 0 THEN
                AssAmt := SalesCrMemoLine."GST Assessable Value (LCY)"
            ELSE
                //B2BUPG1.0>> 
                AssAmt := SalesCrMemoLine.Amount;
            /*IF SalesCrMemoLine."GST Base Amount" <> 0 THEN
                AssAmt := SalesCrMemoLine."GST Base Amount"
            ELSE
                AssAmt := SalesCrMemoLine."Line Amount" + SalesCrMemoLine."Line Discount Amount";*/
            //B2BUPG1.0<<
            //END;
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
            TotItemVal := SalesCrMemoLine."Amount Including VAT" + TotGSTAmt;
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
        END;
        /*
        JsonTextWriter.WriteStartObject;
        JsonTextWriter.WritePropertyName('item_serial_number');
        IF SlNo <> 0 THEN
            JsonTextWriter.WriteValue(FORMAT(SlNo))
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('product_description');
        IF PrdDesc <> '' THEN
            JsonTextWriter.WriteValue(PrdDesc)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('is_service');
        IF IsServc <> '' THEN
            JsonTextWriter.WriteValue(IsServc)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('hsn_code');
        IF HsnCd <> '' THEN
            JsonTextWriter.WriteValue(HsnCd)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('bar_code');//Need to update
        IF BarCode <> '' THEN
            JsonTextWriter.WriteValue(BarCode)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('quantity');
        JsonTextWriter.WriteValue(FORMAT(Qty));
        JsonTextWriter.WritePropertyName('free_quantity');
        JsonTextWriter.WriteValue(FORMAT(FreeQty));
        JsonTextWriter.WritePropertyName('unit');
        IF Unit <> '' THEN
            JsonTextWriter.WriteValue(Unit)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('unit_price');
        JsonTextWriter.WriteValue(UnitPrice);
        JsonTextWriter.WritePropertyName('total_amount');
        JsonTextWriter.WriteValue(TotAmt);
        JsonTextWriter.WritePropertyName('pre_tax_value');
        JsonTextWriter.WriteValue(PreTaxVal);
        JsonTextWriter.WritePropertyName('discount');
        JsonTextWriter.WriteValue(Discount);
        JsonTextWriter.WritePropertyName('other_charge');
        JsonTextWriter.WriteValue(OthChrg);
        JsonTextWriter.WritePropertyName('assessable_value');
        JsonTextWriter.WriteValue(AssAmt);
        JsonTextWriter.WritePropertyName('gst_rate');
        JsonTextWriter.WriteValue(GstRt);
        JsonTextWriter.WritePropertyName('igst_amount');
        JsonTextWriter.WriteValue(IgstAmt);
        JsonTextWriter.WritePropertyName('cgst_amount');
        JsonTextWriter.WriteValue(CgstAmt);
        JsonTextWriter.WritePropertyName('sgst_amount');
        JsonTextWriter.WriteValue(SgstAmt);
        JsonTextWriter.WritePropertyName('cess_rate');
        JsonTextWriter.WriteValue(CesRt);
        JsonTextWriter.WritePropertyName('cess_amount');
        JsonTextWriter.WriteValue(CesAmt);
        JsonTextWriter.WritePropertyName('cess_nonadvol_amount');
        JsonTextWriter.WriteValue(CesNonAdvlAmt);
        JsonTextWriter.WritePropertyName('state_cess_rate');
        JsonTextWriter.WriteValue(StateCesRt);
        JsonTextWriter.WritePropertyName('state_cess_amount');
        JsonTextWriter.WriteValue(StateCesAmt);
        JsonTextWriter.WritePropertyName('state_cess_nonadvol_amount');
        JsonTextWriter.WriteValue(StateCesNonAdvlAmt);
        JsonTextWriter.WritePropertyName('total_item_value');
        JsonTextWriter.WriteValue(TotItemVal);
        JsonTextWriter.WritePropertyName('country_origin');
        JsonTextWriter.WriteValue(OrgCntry);
        JsonTextWriter.WritePropertyName('order_line_reference');
        JsonTextWriter.WriteValue(OrdLineRef);
        JsonTextWriter.WritePropertyName('product_serial_number');
        IF PrdSlNo <> '' THEN
            JsonTextWriter.WriteValue(PrdSlNo)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);

        IF LotExist THEN
            ReadBchDtls(LineNo)
        ELSE BEGIN
            JsonTextWriter.WritePropertyName('batch_details');
            JsonTextWriter.WriteValue(GlobalNULL);
        END;

        JsonTextWriter.WritePropertyName('attribute_details');//need to update
        JsonTextWriter.WriteValue(GlobalNULL);

        JsonTextWriter.WriteEndObject;
                */
        if SlNo <> 0 then begin
            SlNoL := FORMAT(Slno);
            JSOItemLineL.Add('item_serial_number', SlNoL);
        end else
            JSOItemLineL.Add('item_serial_number', JVObjG.AsToken());
        if PrdDesc <> '' then
            JSOItemLineL.Add('product_description', PrdDesc)
        else
            JSOItemLineL.Add('product_description', JVObjG.AsToken());
        if IsServc <> '' then
            JSOItemLineL.Add('is_service', IsServc)
        else
            JSOItemLineL.Add('is_service', JVObjG.AsToken());
        if HsnCd <> '' then
            JSOItemLineL.Add('hsn_code', HsnCd)
        else
            JSOItemLineL.Add('hsn_code', JVObjG.AsToken());
        if BarCode <> '' then
            JSOItemLineL.Add('bar_code', BarCode)
        else
            JSOItemLineL.Add('bar_code', JVObjG.AsToken());
        QTYL := Format(Qty);
        JSOItemLineL.Add('quantity', QTYL);
        FreeQtyL := Format(FreeQty);
        JSOItemLineL.Add('free_quantity', FreeQtyL);
        if Unit <> '' then
            JSOItemLineL.Add('unit', Unit)
        else
            JSOItemLineL.Add('unit', JVObjG.AsToken());
        JSOItemLineL.Add('unit_price', UnitPrice);
        JSOItemLineL.Add('total_amount', TotAmt);
        JSOItemLineL.Add('pre_tax_value', PreTaxVal);
        JSOItemLineL.Add('discount', Discount);
        JSOItemLineL.Add('other_charge', OthChrg);
        JSOItemLineL.Add('assessable_value', AssAmt);
        JSOItemLineL.Add('gst_rate', GstRt);
        JSOItemLineL.Add('igst_amount', IgstAmt);
        JSOItemLineL.Add('cgst_amount', CgstAmt);
        JSOItemLineL.Add('sgst_amount', SgstAmt);
        JSOItemLineL.Add('cess_rate', CesRt);
        JSOItemLineL.Add('cess_amount', CesAmt);
        JSOItemLineL.Add('cess_nonadvol_amount', CesNonAdvlAmt);
        JSOItemLineL.Add('state_cess_rate', StateCesRt);
        JSOItemLineL.Add('state_cess_amount', StateCesAmt);
        JSOItemLineL.Add('state_cess_nonadvol_amount', StateCesNonAdvlAmt);
        JSOItemLineL.Add('total_item_value', TotItemVal);
        JSOItemLineL.Add('country_origin', OrgCntry);
        JSOItemLineL.Add('order_line_reference', OrdLineRef);
        if PrdSlNo <> '' then
            JSOItemLineL.Add('product_serial_number', PrdSlNo)
        else
            JSOItemLineL.Add('product_serial_number', JVObjG.AsToken());
        IF LotExist THEN
            ReadBchDtls(LineNo)
        ELSE
            JSOItemLineL.Add('batch_details', JVObjG.AsToken());
        JSOItemLineL.Add('attribute_details', JVObjG.AsToken());


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
            InvoiceRowID := ItemTrackingManagement.ComposeRowID(DATABASE::"Sales Cr.Memo Line", 0, DocumentNo, '', 0, LineNo);
        ValueEntryRelation.SETCURRENTKEY("Source RowId");
        ValueEntryRelation.SETRANGE("Source RowId", InvoiceRowID);
        IF ValueEntryRelation.FINDSET THEN BEGIN
            //JsonTextWriter.WritePropertyName('batch_details');
            //JsonTextWriter.WriteStartObject;
            REPEAT
                ValueEntry.GET(ValueEntryRelation."Value Entry No.");
                ItemLedgerEntry.GET(ValueEntry."Item Ledger Entry No.");
                IF ItemLedgerEntry."Invoiced Quantity" <> 0 THEN
                    WriteBchDtls(
                      COPYSTR(ItemLedgerEntry."Lot No." + ItemLedgerEntry."Serial No.", 1, 20),
                      FORMAT(ItemLedgerEntry."Expiration Date", 0, '<Day,2>/<Month,2>/<Year4>'),
                      FORMAT(ItemLedgerEntry."Warranty Date", 0, '<Day,2>/<Month,2>/<Year4>'), JSObBatchDtlaG);
            UNTIL ValueEntryRelation.NEXT = 0;
            JSOAsstokenG.Add('batch_details', JSObBatchDtlaG);
            //JsonTextWriter.WriteEndObject;
        END;
    end;

    local procedure WriteBchDtls(Nm: Text[20]; ExpDt: Text[10]; WrDt: Text[10]; var JSObchdtlsL: JsonObject);
    begin
        /*
        JsonTextWriter.WritePropertyName('name');
        IF Nm <> '' THEN
            JsonTextWriter.WriteValue(Nm)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('expiry_date');
        IF ExpDt <> '' THEN
            JsonTextWriter.WriteValue(ExpDt)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('warranty_date');
        IF WrDt <> '' THEN
            JsonTextWriter.WriteValue(WrDt)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
            */
        if Nm <> '' then
            JSObchdtlsL.Add('name', Nm)
        else
            JSObchdtlsL.Add('name', JVObjG.AsToken());
        if ExpDt <> '' then
            JSObchdtlsL.Add('expiry_date', ExpDt)
        else
            JSObchdtlsL.Add('expiry_date', JVObjG.AsToken());
        if WrDt <> '' then
            JSObchdtlsL.Add('expiry_date', WrDt)
        else
            JSObchdtlsL.Add('expiry_date', WrDt);

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
        END ELSE BEGIN
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

        IF (Nm = '') AND (AccDet = '') AND (Mode = '') AND (FinInsBr = '') AND (PayTerm = '') AND (PayInstr = '') AND
          (CrTrn = '') AND (DirDr = '') AND (CrDay = 0) AND (PaidAmt = 0) AND (PaymtDue = 0)
        THEN BEGIN
            //JsonTextWriter.WritePropertyName('payment_details');
            //JsonTextWriter.WriteValue(GlobalNULL);
            JSOAsstokenG.Add('payment_details', JVObjG.AsToken());
        END ELSE
            WritePayDtls(Nm, AccDet, Mode, FinInsBr, PayTerm, PayInstr, CrTrn, DirDr, CrDay, PaidAmt, PaymtDue);
    end;

    local procedure WritePayDtls(Nm: Text[100]; AccDet: Text[18]; Mode: Text[18]; FinInsBr: Text[11]; PayTerm: Text[100]; PayInstr: Text[100]; CrTrn: Text[100]; DirDr: Text[100]; CrDay: Integer; PaidAmt: Decimal; PaymtDue: Decimal);
    begin
        /*
        JsonTextWriter.WritePropertyName('payment_details');
        JsonTextWriter.WriteStartObject;

        JsonTextWriter.WritePropertyName('bank_account_number');
        IF AccDet <> '' THEN
            JsonTextWriter.WriteValue(AccDet)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('paid_balance_amount');
        JsonTextWriter.WriteValue(PaidAmt);
        JsonTextWriter.WritePropertyName('credit_days');
        JsonTextWriter.WriteValue(CrDay);
        JsonTextWriter.WritePropertyName('credit_transfer');
        IF CrTrn <> '' THEN
            JsonTextWriter.WriteValue(CrTrn)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('direct_debit');
        IF DirDr <> '' THEN
            JsonTextWriter.WriteValue(DirDr)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('branch_or_ifsc');
        IF FinInsBr <> '' THEN
            JsonTextWriter.WriteValue(FinInsBr)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('payment_mode');
        IF Mode <> '' THEN
            JsonTextWriter.WriteValue(Mode)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('payee_name');
        IF Nm <> '' THEN
            JsonTextWriter.WriteValue(Nm)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('outstanding_amount');
        JsonTextWriter.WriteValue(PaymtDue);
        JsonTextWriter.WritePropertyName('payment_instruction');
        IF PayInstr <> '' THEN
            JsonTextWriter.WriteValue(PayInstr)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('payment_term');
        IF PayTerm <> '' THEN
            JsonTextWriter.WriteValue(PayTerm)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);

        JsonTextWriter.WriteEndObject;
        */
        if AccDet <> '' then
            JSObjPayDtlsG.Add('bank_account_number', AccDet)
        else
            JSObjPayDtlsG.Add('bank_account_number', JVObjG.AsToken());
        JSObjPayDtlsG.Add('paid_balance_amount', PaidAmt);
        JSObjPayDtlsG.Add('credit_days', CrDay);
        if CrTrn <> '' then
            JSObjPayDtlsG.Add('credit_transfer', CrTrn)
        else
            JSObjPayDtlsG.Add('credit_transfer', JVObjG.AsToken());
        if DirDr <> '' then
            JSObjPayDtlsG.Add('direct_debit', DirDr)
        else
            JSObjPayDtlsG.Add('direct_debit', JVObjG.AsToken());
        if FinInsBr <> '' then
            JSObjPayDtlsG.Add('branch_or_ifsc', FinInsBr)
        else
            JSObjPayDtlsG.Add('branch_or_ifsc', JVObjG.AsToken());
        if Mode <> '' then
            JSObjPayDtlsG.Add('payment_mode', Mode)
        else
            JSObjPayDtlsG.Add('payment_mode', JVObjG.AsToken());
        if nm <> '' then
            JSObjPayDtlsG.Add('payee_name', Nm)
        else
            JSObjPayDtlsG.Add('payee_name', JVObjG.AsToken());
        if PaymtDue <> 0 then
            JSObjPayDtlsG.Add('outstanding_amount', PaymtDue)
        else
            JSObjPayDtlsG.Add('outstanding_amount', JVObjG.AsToken());
        if PayInstr <> '' then
            JSObjPayDtlsG.Add('payment_instruction', PayInstr)
        else
            JSObjPayDtlsG.Add('payment_instruction', JVObjG.AsToken());
        if PayTerm <> '' then
            JSObjPayDtlsG.Add('payment_term', PayTerm)
        else
            JSObjPayDtlsG.Add('payment_term', JVObjG.AsToken());
        JSOAsstokenG.Add('payment_details', JSObjPayDtlsG);


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
        END ELSE BEGIN
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

        IF (InvRm = '') AND (InvStDt = '') AND (InvEndDt = '') AND
          (InvNo = '') AND (InvDt = '') AND (OthRefNo = '') AND
          (RecAdvRefr = '') AND (RecAdvDt = '') AND (TendRefr = '') AND (ContrRefr = '') AND
          (ExtRefr = '') AND (ProjRefr = '') AND (PORefr = '') AND (PORefDt = '')
        THEN BEGIN
            //JsonTextWriter.WritePropertyName('reference_details');
            //JsonTextWriter.WriteValue(GlobalNULL);
            JSOAsstokenG.Add('reference_details', JVObjG.AsToken());
        END ELSE
            WriteRefDtls(InvRm, InvStDt, InvEndDt, InvNo, InvDt, OthRefNo, RecAdvRefr, RecAdvDt, TendRefr, ContrRefr, ExtRefr, ProjRefr, PORefr, PORefDt);
    end;

    local procedure WriteRefDtls(InvRm: Text[100]; InvStDt: Text[10]; InvEndDt: Text[10]; InvNo: Text[16]; InvDt: Text[10]; OthRefNo: Text[20]; RecAdvRefr: Text[20]; RecAdvDt: Text[10]; TendRefr: Text[20]; ContrRefr: Text[20]; ExtRefr: Text[20]; ProjRefr: Text[20]; PORefr: Text[16]; PORefDt: Text[10]);
    begin
        /*
        JsonTextWriter.WritePropertyName('reference_details');
        JsonTextWriter.WriteStartObject;

        JsonTextWriter.WritePropertyName('invoice_remarks');
        IF InvRm <> '' THEN
            JsonTextWriter.WriteValue(InvRm)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);

        JsonTextWriter.WritePropertyName('document_period_details');
        JsonTextWriter.WriteStartObject;
        JsonTextWriter.WritePropertyName('invoice_period_start_date');
        IF InvStDt <> '' THEN
            JsonTextWriter.WriteValue(InvStDt)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('invoice_period_end_date');
        IF InvEndDt <> '' THEN
            JsonTextWriter.WriteValue(InvEndDt)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WriteEndObject;
        JsonTextWriter.WriteEndObject;
        */
        if InvRm <> '' then
            JSObjRefDtlsG.Add('invoice_remarks', InvRm)
        else
            JSObjRefDtlsG.Add('invoice_remarks', JVObjG.AsToken());
        JSObjRefDtlsG.Add('document_period_details', JVObjG.AsToken());
        if InvDt <> '' then
            JSObjRefDtlsG.Add('invoice_period_start_date', InvDt)
        else
            JSObjRefDtlsG.Add('invoice_period_start_date', JVObjG.AsToken());
        if InvEndDt <> '' then
            JSObjRefDtlsG.Add('invoice_period_end_date', InvEndDt)
        else
            JSObjRefDtlsG.Add('invoice_period_end_date', JVObjG.AsToken());
        JSOAsstokenG.Add('reference_details', JSObjRefDtlsG);

        WritePrecDocDtls(InvNo, InvDt, OthRefNo);

        WriteContrDtls(RecAdvRefr, RecAdvDt, TendRefr, ContrRefr, ExtRefr, ProjRefr, PORefr, PORefDt);
    end;

    local procedure WritePrecDocDtls(InvNo: Text[16]; InvDt: Text[10]; OthRefNo: Text[20]);
    begin
        /*
        JsonTextWriter.WritePropertyName('preceding_document_details');
        JsonTextWriter.WriteStartArray;
        REPEAT
            JsonTextWriter.WriteStartObject;

            JsonTextWriter.WritePropertyName('reference_of_original_invoice');
            IF InvNo <> '' THEN
                JsonTextWriter.WriteValue(InvNo)
            ELSE
                JsonTextWriter.WriteValue(GlobalNULL);
            JsonTextWriter.WritePropertyName('preceding_invoice_date');
            IF InvDt <> '' THEN
                JsonTextWriter.WriteValue(InvDt)
            ELSE
                JsonTextWriter.WriteValue(GlobalNULL);
            JsonTextWriter.WritePropertyName('other_reference');
            IF OthRefNo <> '' THEN
                JsonTextWriter.WriteValue(OthRefNo)
            ELSE
                JsonTextWriter.WriteValue(GlobalNULL);
            JsonTextWriter.WriteEndObject;
        UNTIL TRUE;
        JsonTextWriter.WriteEndArray;
        */

        //B2B>>
        JSOAsstokenG.Add('PrecDocDtls', '');
        JSObjPrecDocDtlsG.Add('InvNo', '');
        JSObjPrecDocDtlsG.Add('InvDt', '');
        JSObjPrecDocDtlsG.Add('OthRefNo', '');
        repeat
            if InvNo <> '' then
                JSObjPrecDocDtlsG.Add('InvNo', InvNo)
            else
                JSObjPrecDocDtlsG.Add('InvNo', JVOBJG.AsToken());
            if InvDt <> '' then
                JSObjPrecDocDtlsG.Add('InvDt', '')
            else
                JSObjPrecDocDtlsG.Add('InvDt', JVOBJG.AsToken());
            if OthRefNo <> '' then
                JSObjPrecDocDtlsG.Add('OthRefNo', '')
            else
                JSObjPrecDocDtlsG.Add('OthRefNo', JVOBJG.AsToken());
            JSArrayPreDtlsG.Add(JSObjPrecDocDtlsG);
        until true;
        JSOAsstokenG.Add('PrecDocument', JSArrayPreDtlsG);
        //B2B<<

    end;

    local procedure WriteContrDtls(RecAdvRefr: Text[20]; RecAdvDt: Text[10]; TendRefr: Text[20]; ContrRefr: Text[20]; ExtRefr: Text[20]; ProjRefr: Text[20]; PORefr: Text[16]; PORefDt: Text[10]);
    begin
        /*
        JsonTextWriter.WritePropertyName('contract_details');
        JsonTextWriter.WriteStartArray;
        REPEAT
            JsonTextWriter.WriteStartObject;

            JsonTextWriter.WritePropertyName('receipt_advice_number');
            IF RecAdvRefr <> '' THEN
                JsonTextWriter.WriteValue(RecAdvRefr)
            ELSE
                JsonTextWriter.WriteValue(GlobalNULL);
            JsonTextWriter.WritePropertyName('receipt_advice_date');
            IF RecAdvDt <> '' THEN
                JsonTextWriter.WriteValue(RecAdvDt)
            ELSE
                JsonTextWriter.WriteValue(GlobalNULL);
            JsonTextWriter.WritePropertyName('batch_reference_number');
            IF TendRefr <> '' THEN
                JsonTextWriter.WriteValue(TendRefr)
            ELSE
                JsonTextWriter.WriteValue(GlobalNULL);
            JsonTextWriter.WritePropertyName('contract_reference_number');
            IF ContrRefr <> '' THEN
                JsonTextWriter.WriteValue(ContrRefr)
            ELSE
                JsonTextWriter.WriteValue(GlobalNULL);
            JsonTextWriter.WritePropertyName('other_reference');
            IF ExtRefr <> '' THEN
                JsonTextWriter.WriteValue(ExtRefr)
            ELSE
                JsonTextWriter.WriteValue(GlobalNULL);
            JsonTextWriter.WritePropertyName('project_reference_number');
            IF ProjRefr <> '' THEN
                JsonTextWriter.WriteValue(ProjRefr)
            ELSE
                JsonTextWriter.WriteValue(GlobalNULL);
            JsonTextWriter.WritePropertyName('vendor_po_reference_number');
            IF PORefr <> '' THEN
                JsonTextWriter.WriteValue(PORefr)
            ELSE
                JsonTextWriter.WriteValue(GlobalNULL);
            JsonTextWriter.WritePropertyName('vendor_po_reference_date');
            IF PORefDt <> '' THEN
                JsonTextWriter.WriteValue(PORefDt)
            ELSE
                JsonTextWriter.WriteValue(GlobalNULL);
            JsonTextWriter.WriteEndObject;
        UNTIL TRUE;
        JsonTextWriter.WriteEndArray;
        */
        JSOAsstokenG.Add('contract_details', '');
        repeat
            if RecAdvRefr <> '' then
                JObjContrDtlsG.Add('receipt_advice_number', RecAdvRefr)
            else
                JObjContrDtlsG.Add('InvNo', JVOBJG.AsToken());
            if RecAdvDt <> '' then
                JObjContrDtlsG.Add('receipt_advice_date', RecAdvDt)
            else
                JObjContrDtlsG.Add('InvDt', JVOBJG.AsToken());
            if TendRefr <> '' then
                JObjContrDtlsG.Add('batch_reference_number', TendRefr)
            else
                JObjContrDtlsG.Add('batch_reference_number', JVOBJG.AsToken());
            if ContrRefr <> '' then
                JObjContrDtlsG.Add('contract_reference_number', ContrRefr)
            else
                JObjContrDtlsG.Add('contract_reference_number', JVOBJG.AsToken());
            if ExtRefr <> '' then
                JObjContrDtlsG.Add('other_reference', ExtRefr)
            else
                JObjContrDtlsG.Add('other_reference', JVOBJG.AsToken());
            if ProjRefr <> '' then
                JObjContrDtlsG.Add('project_reference_number', ProjRefr)
            else
                JObjContrDtlsG.Add('project_reference_number', JVOBJG.AsToken());
            if PORefr <> '' then
                JObjContrDtlsG.Add('vendor_po_reference_number', PORefr)
            else
                JObjContrDtlsG.Add('vendor_po_reference_number', JVOBJG.AsToken());

            if PORefDt <> '' then
                JObjContrDtlsG.Add('vendor_po_reference_date', PORefDt)
            else
                JObjContrDtlsG.Add('vendor_po_reference_date', JVOBJG.AsToken());

            JArrayContrDtlsG.Add(JObjContrDtlsG);
        until true;
        JSOAsstokenG.Add('Contract', JArrayContrDtlsG);
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
        END ELSE BEGIN
            Url := '';//Supporting Document URL
            Docs := '';//Supporting document in Base64 Format
            Info := '';//Any additional info
        END;

        IF (Url = '') AND (Docs = '') AND (Info = '') THEN BEGIN
            // JsonTextWriter.WritePropertyName('additional_document_details');
            //JsonTextWriter.WriteValue(GlobalNULL);
            JSOAsstokenG.Add('additional_document_details', JVOBJG.AsToken());
        END ELSE BEGIN
            // JsonTextWriter.WritePropertyName('additional_document_details');
            //JsonTextWriter.WriteStartArray;
            JSOAsstokenG.Add('additional_document_details', '');
            REPEAT
                WriteAddlDocDtls(Url, Docs, Info, JSODcoDtlsG);
                JSArryDocDtlsG.Add(JSODcoDtlsG);
            UNTIL TRUE;
            JSOAsstokenG.Add('AddlDocument', JSArryDocDtlsG);
            //JsonTextWriter.WriteEndArray;
        END;
    end;

    local procedure WriteAddlDocDtls(Url: Text[100]; Docs: Text; Info: Text; var JSODcoDtlsL: JsonObject);
    begin
        /*
        JsonTextWriter.WriteStartObject;

        JsonTextWriter.WritePropertyName('supporting_document_url');
        IF Url <> '' THEN
            JsonTextWriter.WriteValue(Url)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('supporting_document');
        IF Docs <> '' THEN
            JsonTextWriter.WriteValue(Docs)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WritePropertyName('additional_information');
        IF Info <> '' THEN
            JsonTextWriter.WriteValue(Info)
        ELSE
            JsonTextWriter.WriteValue(GlobalNULL);
        JsonTextWriter.WriteEndObject;
        */
        if Url <> '' then
            JSODcoDtlsL.Add('supporting_document_url', Url)
        else
            JSODcoDtlsL.Add('supporting_document_url', JVOBJG.AsToken());
        if Docs <> '' then
            JSODcoDtlsL.Add('supporting_document', Docs)
        else
            JSODcoDtlsL.Add('supporting_document', JVOBJG.AsToken());
        if Info <> '' then
            JSODcoDtlsL.Add('additional_information', Info)
        else
            JSODcoDtlsL.Add('additional_information', JVOBJG.AsToken());
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
        TotInvValAddCur: Decimal;
        TotCesNonAdval: Decimal;
        TotInvValFc: Decimal;
    begin
        GetGSTVal(AssVal, CgstVal, SgstVal, IgstVal, CesVal, StCesVal, CesNonAdval, Disc, OthChrg, TotInvVal, TotInvValFc);
        RndOffAmt := GetRndOffAmt;
        WriteValDtls(AssVal, CgstVal, SgstVal, IgstVal, CesVal, StCesVal, RndOffAmt, TotInvVal, TotInvValAddCur, TotCesNonAdval, Disc, OthChrg);
    end;

    local procedure WriteValDtls(Assval: Decimal; CgstVal: Decimal; SgstVAl: Decimal; IgstVal: Decimal; CesVal: Decimal; StCesVal: Decimal; RndOffAmt: Decimal; TotInvVal: Decimal; TotInvValAddCur: Decimal; TotCesNonAdval: Decimal; Disc: Decimal; OthChrg: Decimal);
    begin
        /*
        JsonTextWriter.WritePropertyName('value_details');
        JsonTextWriter.WriteStartObject;

        JsonTextWriter.WritePropertyName('total_assessable_value');
        JsonTextWriter.WriteValue(Assval);
        JsonTextWriter.WritePropertyName('total_cgst_value');
        JsonTextWriter.WriteValue(CgstVal);
        JsonTextWriter.WritePropertyName('total_sgst_value');
        JsonTextWriter.WriteValue(SgstVAl);
        JsonTextWriter.WritePropertyName('total_igst_value');
        JsonTextWriter.WriteValue(IgstVal);
        JsonTextWriter.WritePropertyName('total_cess_value');
        JsonTextWriter.WriteValue(CesVal);
        JsonTextWriter.WritePropertyName('total_cess_nonadvol_value');
        JsonTextWriter.WriteValue(TotCesNonAdval);
        JsonTextWriter.WritePropertyName('total_discount');
        JsonTextWriter.WriteValue(Disc);
        JsonTextWriter.WritePropertyName('total_other_charge');
        JsonTextWriter.WriteValue(OthChrg);
        JsonTextWriter.WritePropertyName('total_invoice_value');
        JsonTextWriter.WriteValue(TotInvVal);
        JsonTextWriter.WritePropertyName('total_cess_value_of_state');
        JsonTextWriter.WriteValue(StCesVal);
        JsonTextWriter.WritePropertyName('round_off_amount');
        JsonTextWriter.WriteValue(RndOffAmt);
        JsonTextWriter.WritePropertyName('total_invoice_value_additional_currency');
        JsonTextWriter.WriteValue(TotInvValAddCur);

        JsonTextWriter.WriteEndObject;
        */

        JOValDtlsG.Add('total_assessable_value', Assval);
        JOValDtlsG.Add('total_cgst_value', CgstVal);
        JOValDtlsG.Add('total_sgst_value', SgstVAl);
        JOValDtlsG.Add('total_igst_value', IgstVal);
        JOValDtlsG.Add('total_cess_value', CesVal);
        JOValDtlsG.Add('total_cess_nonadvol_value', TotCesNonAdval);
        JOValDtlsG.Add('total_discount', Disc);
        JOValDtlsG.Add('total_other_charge', OthChrg);
        JOValDtlsG.Add('total_invoice_value', TotInvVal);
        JOValDtlsG.Add('total_cess_value_of_state', StCesVal);
        JOValDtlsG.Add('round_off_amount', RndOffAmt);
        JOValDtlsG.Add('total_invoice_value_additional_currency', TotInvValAddCur);
        JSOAsstokenG.Add('value_details', JOValDtlsG);

    end;

    procedure SetSalesInvHeader(SalesInvoiceHeaderBuff: Record "Sales Invoice Header");
    begin
        SalesInvoiceHeader := SalesInvoiceHeaderBuff;
        IsInvoice := TRUE;
    end;

    procedure SetCrMemoHeader(SalesCrMemoHeaderBuff: Record "Sales Cr.Memo Header");
    begin
        SalesCrMemoHeader := SalesCrMemoHeaderBuff;
        IsInvoice := FALSE;
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
        CurrencyCode: Code[10];
        CurrencyFactor: Decimal;
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        TotalGSTAmount: Decimal;
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        DetailedGSTLedgerEntry.SETRANGE("Document No.", DocNo);
        DetailedGSTLedgerEntry.SETRANGE("Document Line No.", LineNo);

        GstRt := 0;
        CgstAmt := 0;
        SgstAmt := 0;
        IgstAmt := 0;
        DetailedGSTLedgerEntry.SETRANGE("GST Component Code", 'CGST');
        IF DetailedGSTLedgerEntry.FINDFIRST THEN BEGIN
            GstRt := DetailedGSTLedgerEntry."GST %";
            CgstAmt := ABS(DetailedGSTLedgerEntry."GST Amount");
        END ELSE
            GstRt := 0;

        DetailedGSTLedgerEntry.SETRANGE("GST Component Code", 'SGST');
        IF DetailedGSTLedgerEntry.FINDFIRST THEN BEGIN
            GstRt += DetailedGSTLedgerEntry."GST %";
            SgstAmt += ABS(DetailedGSTLedgerEntry."GST Amount");
        END;

        DetailedGSTLedgerEntry.SETRANGE("GST Component Code", 'IGST');
        IF DetailedGSTLedgerEntry.FINDFIRST THEN BEGIN
            GstRt := DetailedGSTLedgerEntry."GST %";
            IgstAmt := ABS(DetailedGSTLedgerEntry."GST Amount");
        END;

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
                    //IF GSTComponent.GET(DetailedGSTLedgerEntry."GST Component Code") THEN
                    //    IF GSTComponent."Exclude from Reports" THEN //B2BUPG1.0
                            IF DetailedGSTLedgerEntry."GST %" > 0 THEN BEGIN
                        StateCesRt := DetailedGSTLedgerEntry."GST %";
                        StateCesAmt := ABS(DetailedGSTLedgerEntry."GST Amount");
                    END ELSE
                        StateCesNonAdvlAmt := ABS(DetailedGSTLedgerEntry."GST Amount");
            UNTIL DetailedGSTLedgerEntry.NEXT = 0;

        //LCY to FCY conversion
        IF IsInvoice THEN BEGIN
            IF SalesInvoiceHeader."Currency Code" = '' THEN
                EXIT;
            CurrencyCode := SalesInvoiceHeader."Currency Code";
            CurrencyFactor := SalesInvoiceHeader."Currency Factor";
        END ELSE BEGIN
            IF SalesCrMemoHeader."Currency Code" = '' THEN
                EXIT;
            CurrencyCode := SalesCrMemoHeader."Currency Code";
            CurrencyFactor := SalesCrMemoHeader."Currency Factor";
        END;

        IF IgstAmt <> 0 THEN
            IgstAmt := ROUND(CurrExchRate.ExchangeAmtLCYToFCY(WORKDATE, CurrencyCode, IgstAmt, CurrencyFactor), 0.01, '=');
        IF CgstAmt <> 0 THEN
            CgstAmt := ROUND(CurrExchRate.ExchangeAmtLCYToFCY(WORKDATE, CurrencyCode, CgstAmt, CurrencyFactor), 0.01, '=');
        IF SgstAmt <> 0 THEN
            SgstAmt := ROUND(CurrExchRate.ExchangeAmtLCYToFCY(WORKDATE, CurrencyCode, SgstAmt, CurrencyFactor), 0.01, '=');
        IF CessAmt <> 0 THEN
            CessAmt := ROUND(CurrExchRate.ExchangeAmtLCYToFCY(WORKDATE, CurrencyCode, CessAmt, CurrencyFactor), 0.01, '=');
        IF CesNonAdvlAmt <> 0 THEN
            CesNonAdvlAmt := ROUND(CurrExchRate.ExchangeAmtLCYToFCY(WORKDATE, CurrencyCode, CesNonAdvlAmt, CurrencyFactor), 0.01, '=');
        IF StateCesAmt <> 0 THEN
            StateCesAmt := ROUND(CurrExchRate.ExchangeAmtLCYToFCY(WORKDATE, CurrencyCode, StateCesAmt, CurrencyFactor), 0.01, '=');
        IF StateCesNonAdvlAmt <> 0 THEN
            StateCesNonAdvlAmt := ROUND(CurrExchRate.ExchangeAmtLCYToFCY(WORKDATE, CurrencyCode, StateCesNonAdvlAmt, CurrencyFactor), 0.01, '=');
        TotGSTAmt := CgstAmt + SgstAmt + IgstAmt + CessAmt + CesNonAdvlAmt + StateCesAmt + StateCesNonAdvlAmt;
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
        CurrencyCode: Code[10];
        CurrencyFactor: Decimal;
        IsSEZorExported: Boolean;
        //B2BUPG1.0>> 
        CGSTValue: Decimal;
        SGSTValue: Decimal;
        IGSTValue: Decimal;
        CESSValue: Decimal;
    //B2BUPG1.0<<
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
                    //Disc += SalesInvoiceLine."Inv. Discount Amount"; //DiscBugFix
                    Disc += 0; //DiscBugFix

                    //OthChrg += SalesInvoiceLine."Charges To Customer" + SalesInvoiceLine."TDS/TCS Amount";//v1.03
                    //B2BUPG1.0>>
                    //OthChrg += SalesInvoiceLine."Charges To Customer" + SalesInvoiceLine."Total TDS/TCS Incl. SHE CESS";//v1.03
                    OthChrg := 0;
                //B2BUPG1.0<<
                UNTIL SalesInvoiceLine.NEXT = 0;
        END ELSE BEGIN
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
                    //Disc += SalesCrMemoLine."Inv. Discount Amount"; //DiscBugFix
                    Disc += 0; //DiscBugFix
                    //OthChrg += SalesCrMemoLine."Charges To Customer" + SalesCrMemoLine."TDS/TCS Amount";//v1.03
                    //B2BUPG1.0>>
                    //OthChrg += SalesCrMemoLine."Charges To Customer" + SalesCrMemoLine."Total TDS/TCS Incl SHE CESS";//v1.03
                    OthChrg := 0;
                //B2BUPG1.0<<
                UNTIL SalesCrMemoLine.NEXT = 0;
        END;

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
            UNTIL DetailedGSTLedgerEntry.NEXT = 0;

        GSTLedgerEntry.SETFILTER("GST Component Code", '<>CGST&<>SGST&<>IGST&<>CESS&<>INTERCESS');//BugFix
        IF GSTLedgerEntry.FINDSET THEN BEGIN
            REPEAT
                IF GSTComponent.GET(GSTLedgerEntry."GST Component Code") THEN
                    //IF GSTComponent."Exclude from Reports" THEN //B2BUPG1.0
                        StCesVal += ABS(GSTLedgerEntry."GST Amount");
            UNTIL GSTLedgerEntry.NEXT = 0;
        END;

        IF IsInvoice THEN BEGIN
            CurrencyCode := SalesInvoiceHeader."Currency Code";
            CurrencyFactor := SalesInvoiceHeader."Currency Factor";
            IsSEZorExported := SalesInvoiceHeader."GST Customer Type" IN [SalesInvoiceHeader."GST Customer Type"::"SEZ Development",
                                                                          SalesInvoiceHeader."GST Customer Type"::"SEZ Unit",
                                                                          SalesInvoiceHeader."GST Customer Type"::Export];//v1.03
        END ELSE BEGIN
            CurrencyCode := SalesCrMemoHeader."Currency Code";
            CurrencyFactor := SalesCrMemoHeader."Currency Factor";
            IsSEZorExported := SalesCrMemoHeader."GST Customer Type" IN [SalesCrMemoHeader."GST Customer Type"::"SEZ Development",
                                                                          SalesCrMemoHeader."GST Customer Type"::"SEZ Unit",
                                                                          SalesCrMemoHeader."GST Customer Type"::Export];//v1.03
        END;

        IF CesVal <> 0 THEN
            CesVal := ROUND(CurrExchRate.ExchangeAmtLCYToFCY(WORKDATE, CurrencyCode, CesVal, CurrencyFactor), 1, '=');
        IF StCesVal <> 0 THEN
            StCesVal := ROUND(CurrExchRate.ExchangeAmtLCYToFCY(WORKDATE, CurrencyCode, StCesVal, CurrencyFactor), 1, '=');
        IF CesNonAdval <> 0 THEN
            CesNonAdval := ROUND(CurrExchRate.ExchangeAmtLCYToFCY(WORKDATE, CurrencyCode, CesNonAdval, CurrencyFactor), 1, '=');

        IgstVal := 0;
        CgstVal := 0;
        SgstVal := 0;

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
        END ELSE BEGIN
            CustLedgerEntry.SETRANGE("Document Type", CustLedgerEntry."Document Type"::"Credit Memo");
            CustLedgerEntry.SETRANGE("Customer No.", SalesCrMemoHeader."Bill-to Customer No.");
        END;
        IF CustLedgerEntry.FINDFIRST THEN BEGIN
            CustLedgerEntry.CALCFIELDS(Amount);
            //>>v1.03
            TotInvVal := ABS(CustLedgerEntry.Amount);
            IF IsSEZorExported THEN
                TotInvVal += TotGSTAmt + (CesVal + StCesVal + CesNonAdval);//v1.03
            TotInvValFc := ABS(CustLedgerEntry.Amount);
            //<<v1.03
        END;
    end;

    local procedure GetInvRoundingAcc(): Code[20];
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        CustPosGrpCode: Code[10];
    begin
        IF IsInvoice THEN
            CustPosGrpCode := SalesInvoiceHeader."Customer Posting Group"
        ELSE
            CustPosGrpCode := SalesCrMemoHeader."Customer Posting Group";
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
        END ELSE BEGIN
            SalesCrMemoLine.SETRANGE("Document No.", SalesCrMemoHeader."No.");
            //B2BUPG1.0>>
            //SalesCrMemoLine.SETFILTER("No.", '%1|%2', GetInvRoundingAcc, GetGSTRoundingAcc);
            SalesCrMemoLine.SetFilter("No.", '%1', GetInvRoundingAcc);
            //B2BUPG1.0<<
            SalesCrMemoLine.CALCSUMS(Amount);
            EXIT(SalesCrMemoLine.Amount);
        END;
    end;

    local procedure ExportAsJson(FileName: Text[30]; var PathSaved: Text; JSONText: Text);
    var
        TempFile: File;
        ToFile: Variant;
        NewStream: InStream;
        EInvoiceSetup: Record "E-Invoice Setup";
        TempBlob: Codeunit "Temp Blob";
        outstreamL: OutStream;
        FileMgt: Codeunit "File Management";
    begin
        FileName := DELCHR(FileName, '=', '/\-_*^@');
        ToFile := FileName + '.json';

        EInvoiceSetup.GET;
        PathSaved := EInvoiceSetup."MI JSON Request Path" + FileName + '.json';

        if File.Exists(PathSaved) then
            File.Erase(PathSaved);

        CLEAR(TempBlob);
        //TempBlob.WriteAsText(StringBuilder.ToString, TEXTENCODING::UTF8);
        TempBlob.CreateOutStream(outstreamL, TEXTENCODING::UTF8);
        outstreamL.WriteText(JSONText);
        //TempBlob.EXPORT(PathSaved);
        FileMgt.BLOBExportToServerFile(TempBlob, PathSaved);
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
        EInvoiceSetup: Record "E-Invoice Setup";
        EInvoiceEntry: Record "E-Invoice Entry";
    begin
        RecRef.GETTABLE(Variant);
        CASE RecRef.NUMBER OF
            112:
                CancelSalesInvHdr := Variant;
            114:
                CancelSalesCrMHdr := Variant;
        END;
        //  IF NOT OpenWindow(CancelReason, ReasonRemarks) THEN
        //    EXIT(FALSE);

        IF CancelSalesInvHdr."No." <> '' THEN
            EInvoiceEntry.GET(EInvoiceEntry."Document Type"::"Sales Invoice", CancelSalesInvHdr."No.")
        ELSE
            EInvoiceEntry.GET(EInvoiceEntry."Document Type"::"Sales Cr. Memo", CancelSalesCrMHdr."No.");

        DocumentNo := EInvoiceEntry."Document No.";

        EInvoiceEntry."IRN Cancelled Reason" := CancelReason;
        EInvoiceEntry."IRN Cancelled Remarks" := ReasonRemarks;
        EInvoiceEntry."IRN Cancelled By" := USERID;
        EInvoiceEntry.MODIFY;


        //   IF ISNULL(StringBuilder) THEN
        //     Initialize;

        EInvoiceSetup.GET;
        //>>Building Json format
        /*
        JsonTextWriter.WriteStartObject;
        JsonTextWriter.WritePropertyName('access_token');
        JsonTextWriter.WriteValue(EInvoiceSetup."MI Access Token" + EInvoiceSetup."MI Access Token 2");
        JsonTextWriter.WritePropertyName('user_gstin');
        JsonTextWriter.WriteValue('09AAAPG7885R002');
        JsonTextWriter.WritePropertyName('irn');
        JsonTextWriter.WriteValue(EInvoiceEntry."IRN No.");
        JsonTextWriter.WritePropertyName('cancel_reason');
        JsonTextWriter.WriteValue(CancelReason);
        JsonTextWriter.WritePropertyName('cancel_remarks');
        JsonTextWriter.WriteValue(ReasonRemarks);
        JsonTextWriter.WriteEndObject;
        */
        JOCancelG.Add('access_token', EInvoiceSetup."MI Access Token" + EInvoiceSetup."MI Access Token 2");
        JOCancelG.Add('user_gstin', '09AAAPG7885R002');
        JOCancelG.Add('irn', EInvoiceEntry."IRN No.");
        JOCancelG.Add('cancel_reason', CancelReason);
        JOCancelG.Add('cancel_remarks', ReasonRemarks);
        //<<Building Json format

        //Save Json request file
        //ExportAsJson('Cancel_' + DocumentNo, JsonRequestPath);
        JOCancelG.WriteTo(JSCancelTextG);
        ExportAsJson('Cancel_' + DocumentNo, JsonRequestPath, JSCancelTextG);
        EInvoiceLog.INIT;
        IF CancelSalesInvHdr."No." <> '' THEN
            EInvoiceLog."Document Type" := EInvoiceLog."Document Type"::Invoice
        ELSE
            EInvoiceLog."Document Type" := EInvoiceLog."Document Type"::"Credit Memo";
        EInvoiceLog."Document No." := DocumentNo;
        EInvoiceLog."Request Path" := JsonRequestPath;
        EInvoiceLog.Cancel := TRUE;
        EInvoiceLog.INSERT(true);
        EXIT(TRUE);
    end;

    /*  local procedure OpenWindow(var ResonCode: Text; var ReasonRemarks: Text): Boolean;
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

          LblColumns := LblColumns.Label;
          LblColumns.Text('Cancel Remarks:');
          LblColumns.Left(20);
          LblColumns.Top(30);
          Prompt.Controls.Add(LblColumns);

          TxtColumns := TxtColumns.TextBox;
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

    //B2BUPGSERVICE1.0<< Service Orders
    procedure AccessTokenRequest()
    begin
        JOBJAcctoken.Add('username', 'testeway@mastersindia.co');
        JOBJAcctoken.Add('password', '!@#Demo!@#123');
        JOBJAcctoken.Add('client_id', 'fIXefFyxGNfDWOcCWnj');
        JOBJAcctoken.Add('client_secret', 'QFd6dZvCGqckabKxTapfZgJc');
        JOBJAcctoken.Add('grant_type', 'password');
    end;

    procedure AccessTokenJSON(var JsonFile: Text)
    begin
        JOBJAcctoken.WriteTo(JsonFile);
    end;

    procedure JSONFormat(var JsonFile: Text)
    begin
        JSOAsstokenG.WriteTo(JsonFile);
    end;
    //B2BSaas Body<<
    procedure JSONcanFormat(var JsonFile: Text)
    begin
        JOCancelG.WriteTo(JsonFile);
    end;
}

