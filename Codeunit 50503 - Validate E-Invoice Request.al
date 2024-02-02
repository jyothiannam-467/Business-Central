codeunit 50010 "Validate E-Invoice Request"
{
    // version E-INV,TokenExpiryFix,POSShipToGSTINFix,ValidIRNFix

    // //TokenExpiryFix
    // //HSNFix
    // //ValidIRNFix


    trigger OnRun();
    begin
    end;

    var
        AddrLenErr: Label 'The field %1 Address must be a string with a minimum length of 3 and a maximum length of 100.';
        CancelValidToErr: Label 'IRN Cancellation is allowed within 24 Hours Only.';
        CrMemoAppliedErr: Label 'Active Credit Memo has been applied, you cannot cancel e-invoice.';
        InActiveInvAppliedErr: Label 'InActive Invoice has been applied, you cannot generate e-invoice for this document.';
        ActiveInActiveInvErr: Label 'You cannot apply Active and Inactive invoices to a single document.';
        CrMemoAppliedErr2: Label 'Credit Memo has been applied, you cannot Generate IRN.';
        Structure: Code[10];

    procedure CheckValidations(Variant: Variant);
    var
        CompanyInformation: Record 79;
        LocationBuff: Record 14;
        StateBuff: Record state;
        SalesLine: Record 37;
        Contact: Record 5050;
        ShipToAddr: Record 222;
    begin
        CheckGSTEInvSetup;
        CheckSellerValidations(Variant);
        CheckBuyerValidations(Variant);
        CheckShipToValidations(Variant);
        CheckLineValidations(Variant);
        CheckGenerateIRNValidaitons(Variant);//ValidIRNFix
    end;

    local procedure CheckGSTEInvSetup();
    var
        EInvoiceSetup: Record "E-Invoice Setup";
    begin
        EInvoiceSetup.GET;
        EInvoiceSetup.TESTFIELD("Request URL");
        EInvoiceSetup.TESTFIELD("JSON Request Path");
        EInvoiceSetup.TESTFIELD("JSON Response Path");
        // EInvoiceSetup.TESTFIELD("User Name");
        // EInvoiceSetup.TESTFIELD(Password);
        EInvoiceSetup.TESTFIELD("Access Token Response Path");
        //EInvoiceSetup.TESTFIELD("Access Token Period");//TokenExpiryFix
        EInvoiceSetup.TESTFIELD("Cancel Request URL");
    end;

    local procedure CheckSellerValidations(Variant: Variant);
    var
        RecRef: RecordRef;
        SalesHeader: Record 36;
        SalesInvHdr: Record "Sales Invoice Header";
        SalesCredHdr: Record "Sales Cr.Memo Header";
        CompanyInfo: Record 79;
        LocationBuff: Record 14;
        StateBuff: Record State;
        PostindDateErr: Label 'The posting date should be today or yesterday.';
        TransferShipHdr: Record "Transfer Shipment Header";
        TransferHeader: Record "Transfer Header";
    begin
        RecRef.GETTABLE(Variant);
        CASE RecRef.NUMBER OF
            36:
                BEGIN
                    SalesHeader := Variant;
                    WITH SalesHeader DO BEGIN
                        TESTFIELD("Posting Date");
                        //IF NOT ("Posting Date" IN [TODAY,TODAY - 1]) THEN
                        // ERROR(PostindDateErr);//v1.03
                        TESTFIELD("Location Code");
                        LocationBuff.GET("Location Code");
                        //LocationBuff.TESTFIELD("GST Registration No.");//2016CU19
                        TESTFIELD("Location GST Reg. No.");
                        //LocationBuff.TESTFIELD("User Name");
                        //LocationBuff.TESTFIELD(Password);
                        CompanyInfo.GET;
                        CompanyInfo.TESTFIELD(Name);
                        LocationBuff.TESTFIELD(Address);
                        IF STRLEN(LocationBuff.Address) < 3 THEN
                            ERROR(AddrLenErr, 'Location');
                        LocationBuff.TESTFIELD(City);
                        LocationBuff.TESTFIELD("Post Code");
                        LocationBuff.TESTFIELD("State Code");
                        StateBuff.GET(LocationBuff."State Code");
                        StateBuff.TESTFIELD("State Code (GST Reg. No.)");
                    END;
                END;
            112:
                BEGIN
                    SalesInvHdr := Variant;
                    WITH SalesInvHdr DO BEGIN
                        //        IF NOT ("Posting Date" IN [TODAY,TODAY - 1]) THEN
                        //          ERROR(PostindDateErr);//v1.03
                        TESTFIELD("Location Code");
                        LocationBuff.GET("Location Code");
                        //LocationBuff.TESTFIELD("GST Registration No.");//2016CU19
                        TESTFIELD("Location GST Reg. No.");
                        //LocationBuff.TESTFIELD("User Name");
                        //LocationBuff.TESTFIELD(Password);
                        CompanyInfo.GET;
                        CompanyInfo.TESTFIELD(Name);
                        LocationBuff.TESTFIELD(Address);
                        IF STRLEN(LocationBuff.Address) < 3 THEN
                            ERROR(AddrLenErr, 'Location');
                        LocationBuff.TESTFIELD(City);
                        LocationBuff.TESTFIELD("Post Code");
                        LocationBuff.TESTFIELD("State Code");
                        StateBuff.GET(LocationBuff."State Code");
                        StateBuff.TESTFIELD("State Code (GST Reg. No.)");
                    END;
                END;
            114:
                BEGIN
                    SalesCredHdr := Variant;
                    WITH SalesCredHdr DO BEGIN
                        //ValidIRNFix >>
                        /*
                        IF IsCancelledInvoiceApplied(SalesCredHdr) THEN
                          ERROR(CancelInvAppliedErr);
                        */
                        //ValidIRNFix <<

                        //        IF NOT ("Posting Date" IN [TODAY,TODAY - 1]) THEN
                        //          ERROR(PostindDateErr);//v1.03
                        TESTFIELD("Location Code");
                        LocationBuff.GET("Location Code");
                        //LocationBuff.TESTFIELD("GST Registration No.");//2016CU19
                        TESTFIELD("Location GST Reg. No.");
                        //LocationBuff.TESTFIELD("User Name");
                        //LocationBuff.TESTFIELD(Password);
                        CompanyInfo.GET;
                        CompanyInfo.TESTFIELD(Name);
                        LocationBuff.TESTFIELD(Address);
                        IF STRLEN(LocationBuff.Address) < 3 THEN
                            ERROR(AddrLenErr, 'Location');
                        LocationBuff.TESTFIELD(City);
                        LocationBuff.TESTFIELD("Post Code");
                        LocationBuff.TESTFIELD("State Code");
                        StateBuff.GET(LocationBuff."State Code");
                        StateBuff.TESTFIELD("State Code (GST Reg. No.)");
                    END;
                END;
            //EInvTrans >>
            5740:
                BEGIN
                    TransferHeader := Variant;
                    WITH TransferHeader DO BEGIN
                        TESTFIELD("Transfer-from Code");
                        LocationBuff.GET("Transfer-from Code");
                        LocationBuff.TESTFIELD("GST Registration No.");//2016CU19
                                                                       //TESTFIELD("Location GST Reg. No.");
                                                                       //LocationBuff.TESTFIELD("User Name");
                                                                       //LocationBuff.TESTFIELD(Password);
                        CompanyInfo.GET;
                        CompanyInfo.TESTFIELD(Name);
                        LocationBuff.TESTFIELD(Address);
                        IF STRLEN(LocationBuff.Address) < 3 THEN
                            ERROR(AddrLenErr, 'Location');
                        LocationBuff.TESTFIELD(City);
                        LocationBuff.TESTFIELD("Post Code");
                        LocationBuff.TESTFIELD("State Code");
                        StateBuff.GET(LocationBuff."State Code");
                        StateBuff.TESTFIELD("State Code (GST Reg. No.)");
                    END;
                END;
            5744:
                BEGIN
                    TransferShipHdr := Variant;
                    WITH TransferShipHdr DO BEGIN
                        TESTFIELD("Transfer-from Code");
                        LocationBuff.GET("Transfer-from Code");
                        LocationBuff.TESTFIELD("GST Registration No.");//2016CU19
                                                                       //TESTFIELD("Location GST Reg. No.");
                                                                       //LocationBuff.TESTFIELD("User Name");
                                                                       //LocationBuff.TESTFIELD(Password);
                        CompanyInfo.GET;
                        CompanyInfo.TESTFIELD(Name);
                        LocationBuff.TESTFIELD(Address);
                        IF STRLEN(LocationBuff.Address) < 3 THEN
                            ERROR(AddrLenErr, 'Location');
                        LocationBuff.TESTFIELD(City);
                        LocationBuff.TESTFIELD("Post Code");
                        LocationBuff.TESTFIELD("State Code");
                        StateBuff.GET(LocationBuff."State Code");
                        StateBuff.TESTFIELD("State Code (GST Reg. No.)");
                    END;
                END;
        //EInvTrans <<
        END;

    end;

    local procedure CheckBuyerValidations(Variant: Variant);
    var
        RecRef: RecordRef;
        SalesCredHdr: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        SalesInvHdr: Record "Sales Invoice Header";
        LocationBuff: Record Location;
        StateBuff: Record State;
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        ShipToAddr: Record "Ship-to Address";
        TransferShipHdr: Record "Transfer Shipment Header";
        TransferHeader: Record "Transfer Header";
    begin
        //>> POSShipToGSTINFix
        RecRef.GETTABLE(Variant);
        CASE RecRef.NUMBER OF
            36:
                BEGIN
                    SalesHeader := Variant;
                    WITH SalesHeader DO BEGIN
                        IF "GST Customer Type" = "GST Customer Type"::Export THEN BEGIN
                            TESTFIELD("Bill-to Name");
                            TESTFIELD("Bill-to Address");
                            IF STRLEN("Bill-to Address") < 3 THEN
                                ERROR(AddrLenErr, 'Bill-to Address');
                            TESTFIELD("Bill-to City");
                        END ELSE BEGIN
                            TESTFIELD("Customer GST Reg. No.");
                            //Customer.GET("Bill-to Customer No.");
                            //Customer.TESTFIELD("GST Registration No.");
                            SalesLine.SETRANGE("Document No.", "No.");
                            SalesLine.SETFILTER("No.", '<>%1', '');
                            IF SalesLine.FINDFIRST THEN
                                IF (SalesLine."GST Place of Supply" = SalesLine."GST Place of Supply"::"Ship-to Address") AND
                                  (ShipToAddr.GET("Sell-to Customer No.", "Ship-to Code"))
                                THEN BEGIN
                                    TESTFIELD("Ship-to Name");
                                    TESTFIELD("Ship-to Address");
                                    IF STRLEN("Ship-to Address") < 3 THEN
                                        ERROR(AddrLenErr, 'Ship-to Address');
                                    TESTFIELD("Ship-to City");
                                    //RtnOrdFix >>
                                    //              TESTFIELD("GST Ship-to State Code");
                                    //              StateBuff.GET("GST Ship-to State Code");
                                    //ShipToAddr.GET("Sell-to Customer No.","Ship-to Code");
                                    StateBuff.GET(ShipToAddr.State);
                                    //RtnOrdFix <<
                                    StateBuff.TESTFIELD("State Code (GST Reg. No.)");
                                END ELSE BEGIN
                                    TESTFIELD("Bill-to Name");
                                    TESTFIELD("Bill-to Address");
                                    IF STRLEN("Bill-to Address") < 3 THEN
                                        ERROR(AddrLenErr, 'Bill-to Address');
                                    TESTFIELD("Bill-to City");
                                    TESTFIELD("GST Bill-to State Code");
                                    StateBuff.GET("GST Bill-to State Code");
                                    //Customer.GET("Bill-to Customer No.");
                                    //StateBuff.GET(Customer."State Code");
                                    StateBuff.TESTFIELD("State Code (GST Reg. No.)");
                                END;
                        END;
                    END;
                END;
            112:
                BEGIN
                    SalesInvHdr := Variant;
                    WITH SalesInvHdr DO BEGIN
                        IF "GST Customer Type" = "GST Customer Type"::Export THEN BEGIN
                            TESTFIELD("Bill-to Name");
                            TESTFIELD("Bill-to Address");
                            IF STRLEN("Bill-to Address") < 3 THEN
                                ERROR(AddrLenErr, 'Bill-to Address');
                            TESTFIELD("Bill-to City");
                        END ELSE BEGIN
                            TESTFIELD("Customer GST Reg. No.");
                            //Customer.GET("Bill-to Customer No.");
                            //Customer.TESTFIELD("GST Registration No.");
                            SalesInvoiceLine.SETRANGE("Document No.", "No.");
                            SalesInvoiceLine.SETFILTER("No.", '<>%1', '');
                            IF SalesInvoiceLine.FINDFIRST THEN
                                IF (SalesInvoiceLine."GST Place of Supply" = SalesInvoiceLine."GST Place of Supply"::"Ship-to Address") AND
                                  (ShipToAddr.GET("Sell-to Customer No.", "Ship-to Code"))
                                THEN BEGIN
                                    TESTFIELD("Ship-to Name");
                                    TESTFIELD("Ship-to Address");
                                    IF STRLEN("Ship-to Address") < 3 THEN
                                        ERROR(AddrLenErr, 'Ship-to Address');
                                    TESTFIELD("Ship-to City");
                                    //RtnOrdFix >>
                                    //              TESTFIELD("GST Ship-to State Code");
                                    //              StateBuff.GET("GST Ship-to State Code");
                                    //ShipToAddr.GET("Sell-to Customer No.","Ship-to Code");
                                    StateBuff.GET(ShipToAddr.State);
                                    //RtnOrdFix <<
                                    StateBuff.TESTFIELD("State Code (GST Reg. No.)");
                                END ELSE BEGIN
                                    TESTFIELD("Bill-to Name");
                                    TESTFIELD("Bill-to Address");
                                    IF STRLEN("Bill-to Address") < 3 THEN
                                        ERROR(AddrLenErr, 'Bill-to Address');
                                    TESTFIELD("Bill-to City");
                                    TESTFIELD("GST Bill-to State Code");
                                    StateBuff.GET("GST Bill-to State Code");
                                    //Customer.GET("Bill-to Customer No.");
                                    //StateBuff.GET(Customer."State Code");
                                    StateBuff.TESTFIELD("State Code (GST Reg. No.)");
                                END;
                        END;
                    END;
                END;
            114:
                BEGIN
                    SalesCredHdr := Variant;
                    WITH SalesCredHdr DO BEGIN
                        IF "GST Customer Type" = "GST Customer Type"::Export THEN BEGIN
                            TESTFIELD("Bill-to Name");
                            TESTFIELD("Bill-to Address");
                            IF STRLEN("Bill-to Address") < 3 THEN
                                ERROR(AddrLenErr, 'Bill-to Address');
                            TESTFIELD("Bill-to City");
                        END ELSE BEGIN
                            TESTFIELD("Customer GST Reg. No.");
                            //Customer.GET("Bill-to Customer No.");
                            //Customer.TESTFIELD("GST Registration No.");
                            SalesCrMemoLine.SETRANGE("Document No.", "No.");
                            SalesCrMemoLine.SETFILTER("No.", '<>%1', '');
                            IF SalesCrMemoLine.FINDFIRST THEN
                                IF (SalesCrMemoLine."GST Place of Supply" = SalesCrMemoLine."GST Place of Supply"::"Ship-to Address") AND
                                  (ShipToAddr.GET("Sell-to Customer No.", "Ship-to Code"))
                                THEN BEGIN
                                    TESTFIELD("Ship-to Name");
                                    TESTFIELD("Ship-to Address");
                                    IF STRLEN("Ship-to Address") < 3 THEN
                                        ERROR(AddrLenErr, 'Ship-to Address');
                                    TESTFIELD("Ship-to City");
                                    //RtnOrdFix >>
                                    //              TESTFIELD("GST Ship-to State Code");
                                    //              StateBuff.GET("GST Ship-to State Code");
                                    //ShipToAddr.GET("Sell-to Customer No.","Ship-to Code");
                                    StateBuff.GET(ShipToAddr.State);
                                    //RtnOrdFix <<
                                    StateBuff.TESTFIELD("State Code (GST Reg. No.)");
                                END ELSE BEGIN
                                    TESTFIELD("Bill-to Name");
                                    TESTFIELD("Bill-to Address");
                                    IF STRLEN("Bill-to Address") < 3 THEN
                                        ERROR(AddrLenErr, 'Bill-to Address');
                                    TESTFIELD("Bill-to City");
                                    TESTFIELD("GST Bill-to State Code");
                                    StateBuff.GET("GST Bill-to State Code");
                                    //Customer.GET("Bill-to Customer No.");
                                    //StateBuff.GET(Customer."State Code");
                                    StateBuff.TESTFIELD("State Code (GST Reg. No.)");
                                END;
                        END;
                    END;

                end;
            //EInvTrans >>
            5740:
                BEGIN
                    TransferHeader := Variant;
                    WITH TransferHeader DO BEGIN
                        LocationBuff.GET("Transfer-to Code");
                        LocationBuff.TESTFIELD("GST Registration No.");
                        TESTFIELD("Transfer-to Name");
                        TESTFIELD("Transfer-to Address");
                        TESTFIELD("Transfer-to Address 2");
                        //StateBuff.GET(Customer."State Code");
                        StateBuff.GET(LocationBuff."State Code");
                        StateBuff.TESTFIELD("State Code (GST Reg. No.)");
                    END;
                END;
            5744:
                BEGIN
                    TransferShipHdr := Variant;
                    WITH TransferShipHdr DO BEGIN
                        LocationBuff.GET("Transfer-to Code");
                        LocationBuff.TESTFIELD("GST Registration No.");
                        TESTFIELD("Transfer-to Name");
                        TESTFIELD("Transfer-to Address");
                        TESTFIELD("Transfer-to Address 2");
                        //StateBuff.GET(Customer."State Code");
                        StateBuff.GET(LocationBuff."State Code");
                        StateBuff.TESTFIELD("State Code (GST Reg. No.)");
                    END;
                END;
        //EInvTrans <<
        END;
        //<< POSShipToGSTINFix
    end;

    local procedure CheckShipToValidations(Variant: Variant);
    var
        RecRef: RecordRef;
        ShipToAddr: Record "Ship-to Address";
        SalesLine: Record "Sales Line";
        SalesInvLine: Record "Sales Invoice Line";
        SalesCredLine: Record "Sales Cr.Memo Line";
        StateBuff: Record State;
        SalesCredHdr: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        SalesInvHdr: Record "Sales Invoice Header";
        Customer: Record Customer;
        TransferShipHdr: Record "Transfer Shipment Header";
    begin
        RecRef.GETTABLE(Variant);
        CASE RecRef.NUMBER OF
            36:
                BEGIN
                    SalesHeader := Variant;
                    WITH SalesHeader DO
                        IF ShipToAddr.GET("Sell-to Customer No.", "Ship-to Code") THEN BEGIN
                            TESTFIELD("Ship-to Name");
                            TESTFIELD("Ship-to Address");
                            IF STRLEN("Ship-to Address") < 3 THEN
                                ERROR(AddrLenErr, 'Ship-to Address');
                            TESTFIELD("Ship-to City");
                            IF "GST Customer Type" = "GST Customer Type"::Export THEN
                                EXIT;
                            //ShipToAddr.TESTFIELD("GST Registration No.");
                            //RtnOrdFix >>
                            //StateBuff.GET("GST Ship-to State Code");
                            ShipToAddr.TESTFIELD(State);
                            StateBuff.GET(ShipToAddr.State);
                            //RtnOrdFix <<
                            StateBuff.TESTFIELD("State Code (GST Reg. No.)");
                        END ELSE BEGIN
                            TESTFIELD("Bill-to Name");
                            TESTFIELD("Bill-to Address");
                            IF STRLEN("Bill-to Address") < 3 THEN
                                ERROR(AddrLenErr, 'Bill-to Address');
                            TESTFIELD("Ship-to City");
                            IF "GST Customer Type" = "GST Customer Type"::Export THEN
                                EXIT;
                            TESTFIELD("Customer GST Reg. No.");
                            StateBuff.GET("GST Bill-to State Code");
                            //Customer.GET("Bill-to Customer No.");
                            //Customer.TESTFIELD("GST Registration No.");
                            //StateBuff.GET(Customer."State Code");
                            StateBuff.TESTFIELD("State Code (GST Reg. No.)");
                        END;
                END;
            112:
                BEGIN
                    SalesInvHdr := Variant;
                    WITH SalesInvHdr DO
                        IF ShipToAddr.GET("Sell-to Customer No.", "Ship-to Code") THEN BEGIN
                            TESTFIELD("Ship-to Name");
                            TESTFIELD("Ship-to Address");
                            IF STRLEN("Ship-to Address") < 3 THEN
                                ERROR(AddrLenErr, 'Ship-to Address');
                            TESTFIELD("Ship-to City");
                            IF "GST Customer Type" = "GST Customer Type"::Export THEN
                                EXIT;
                            //ShipToAddr.TESTFIELD("GST Registration No.");
                            //RtnOrdFix >>
                            //StateBuff.GET("GST Ship-to State Code");
                            ShipToAddr.TESTFIELD(State);
                            StateBuff.GET(ShipToAddr.State);
                            //RtnOrdFix <<
                            StateBuff.TESTFIELD("State Code (GST Reg. No.)");
                        END ELSE BEGIN
                            TESTFIELD("Bill-to Name");
                            TESTFIELD("Bill-to Address");
                            IF STRLEN("Bill-to Address") < 3 THEN
                                ERROR(AddrLenErr, 'Bill-to Address');
                            TESTFIELD("Ship-to City");
                            IF "GST Customer Type" = "GST Customer Type"::Export THEN
                                EXIT;
                            TESTFIELD("Customer GST Reg. No.");
                            StateBuff.GET("GST Bill-to State Code");
                            //Customer.GET("Bill-to Customer No.");
                            //Customer.TESTFIELD("GST Registration No.");
                            //StateBuff.GET(Customer."State Code");
                            StateBuff.TESTFIELD("State Code (GST Reg. No.)");
                        END;
                END;
            114:
                BEGIN
                    SalesCredHdr := Variant;
                    WITH SalesCredHdr DO
                        IF ShipToAddr.GET("Sell-to Customer No.", "Ship-to Code") THEN BEGIN
                            TESTFIELD("Ship-to Name");
                            TESTFIELD("Ship-to Address");
                            IF STRLEN("Ship-to Address") < 3 THEN
                                ERROR(AddrLenErr, 'Ship-to Address');
                            TESTFIELD("Ship-to City");
                            IF "GST Customer Type" = "GST Customer Type"::Export THEN
                                EXIT;
                            //ShipToAddr.TESTFIELD("GST Registration No.");
                            //RtnOrdFix >>
                            //StateBuff.GET("GST Ship-to State Code");
                            ShipToAddr.TESTFIELD(State);
                            StateBuff.GET(ShipToAddr.State);
                            //RtnOrdFix <<
                            StateBuff.TESTFIELD("State Code (GST Reg. No.)");
                        END ELSE BEGIN
                            TESTFIELD("Bill-to Name");
                            TESTFIELD("Bill-to Address");
                            IF STRLEN("Bill-to Address") < 3 THEN
                                ERROR(AddrLenErr, 'Bill-to Address');
                            TESTFIELD("Ship-to City");
                            IF "GST Customer Type" = "GST Customer Type"::Export THEN
                                EXIT;
                            TESTFIELD("Customer GST Reg. No.");
                            StateBuff.GET("GST Bill-to State Code");
                            //Customer.GET("Bill-to Customer No.");
                            //Customer.TESTFIELD("GST Registration No.");
                            //StateBuff.GET(Customer."State Code");
                            StateBuff.TESTFIELD("State Code (GST Reg. No.)");
                        END;
                END;
        /*
        //EInvTrans >>
        5744:
          BEGIN
            TransferShipHdr := Variant;
            WITH TransferShipHdr DO BEGIN
              LocationBuff.GET("Transfer-to Code");
              LocationBuff.TESTFIELD("GST Registration No.");
              TESTFIELD("Transfer-to Name");
              TESTFIELD("Transfer-to Address");
              TESTFIELD("Transfer-to Address 2");
              //StateBuff.GET(Customer."State Code");
              StateBuff.GET(LocationBuff."State Code");
              StateBuff.TESTFIELD("State Code (GST Reg. No.)");
            END;
          END;
        //EInvTrans <<
        */
        END;
    end;

    local procedure CheckLineValidations(Variant: Variant);
    var
        RecRef: RecordRef;
        SalesLine: Record "Sales Line";
        SalesInvLine: Record "Sales Invoice Line";
        SalesCredLine: Record "Sales Cr.Memo Line";
        SalesCredHdr: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        SalesInvHdr: Record "Sales Invoice Header";
        UOM: Record "Unit of Measure";
        //GSTManagement: Codeunit 16401;
        NumberFilter: Text;
    begin
        RecRef.GETTABLE(Variant);
        CASE RecRef.NUMBER OF
            36:
                BEGIN
                    SalesHeader := Variant;
                    NumberFilter := '<>''''';
                    IF GetInvRoundingAcc(SalesHeader) <> '' THEN
                        NumberFilter += '&<>' + GetInvRoundingAcc(SalesHeader);
                    IF GetNumberFilter(SalesHeader) <> '' THEN
                        NumberFilter += '&<>' + GetNumberFilter(SalesHeader);
                    WITH SalesHeader DO BEGIN
                        SalesLine.RESET;
                        SalesLine.SETRANGE("Document Type", SalesHeader."Document Type");
                        SalesLine.SETRANGE("Document No.", "No.");
                        //B2BUPG1.0>>
                        //SalesLine.SETFILTER("No.", '<>%1&<>%2&<>%3', '', GetInvRoundingAcc(SalesHeader), GetGSTRoundingAcc);
                        SalesLine.SETFILTER("No.", NumberFilter);
                        //B2BUPG1.0<<
                        IF SalesLine.FINDSET THEN
                            REPEAT
                                SalesLine.TESTFIELD(Quantity);
                                IF SalesLine.Type = SalesLine.Type::Item THEN BEGIN
                                    SalesLine.TESTFIELD("Unit of Measure Code");

                                END;
                                //IF GSTManagement.IsGSTApplicable(Structure) THEN//HSNFix  //B2BUPG1.0
                                SalesLine.TESTFIELD("HSN/SAC Code");
                            UNTIL SalesLine.NEXT = 0;
                    END;
                END;
            112:
                BEGIN
                    SalesInvHdr := Variant;
                    NumberFilter := '<>''''';
                    IF GetInvRoundingAcc(SalesInvHdr) <> '' THEN
                        NumberFilter += '&<>' + GetInvRoundingAcc(SalesInvHdr);
                    IF GetNumberFilter(SalesInvHdr) <> '' THEN
                        NumberFilter += '&<>' + GetNumberFilter(SalesInvHdr);
                    WITH SalesInvHdr DO BEGIN
                        SalesInvLine.RESET;
                        SalesInvLine.SETRANGE("Document No.", "No.");
                        //B2BUPG1.0>>
                        //SalesInvLine.SETFILTER("No.", '<>%1&<>%2&<>%3', '', GetInvRoundingAcc(SalesInvHdr), GetGSTRoundingAcc);
                        SalesInvLine.SETFILTER("No.", NumberFilter);
                        //B2BUPG1.0<<
                        SalesInvLine.SETFILTER(Quantity, '<>%1', 0);
                        IF SalesInvLine.FINDSET THEN
                            REPEAT
                                SalesInvLine.TESTFIELD(Quantity);
                                IF SalesInvLine.Type = SalesInvLine.Type::Item THEN BEGIN
                                    SalesInvLine.TESTFIELD("Unit of Measure Code");

                                END;
                                //IF GSTManagement.IsGSTApplicable(Structure) THEN//HSNFix  //B2BUPG1.0
                                SalesInvLine.TESTFIELD("HSN/SAC Code");
                            UNTIL SalesInvLine.NEXT = 0;
                    END;
                END;
            114:
                BEGIN
                    SalesCredHdr := Variant;
                    NumberFilter := '<>''''';
                    IF GetInvRoundingAcc(SalesCredHdr) <> '' THEN
                        NumberFilter += '&<>' + GetInvRoundingAcc(SalesCredHdr);
                    IF GetNumberFilter(SalesCredHdr) <> '' THEN
                        NumberFilter += '&<>' + GetNumberFilter(SalesCredHdr);
                    WITH SalesCredHdr DO BEGIN
                        SalesCredLine.RESET;
                        SalesCredLine.SETRANGE("Document No.", "No.");
                        //B2BUPG1.0>>
                        //SalesCredLine.SETFILTER("No.", '<>%1&<>%2&<>%3', '', GetInvRoundingAcc(SalesCredHdr), GetGSTRoundingAcc);
                        SalesCredLine.SETFILTER("No.", NumberFilter);
                        //B2BUPG1.0<<
                        SalesCredLine.SETFILTER(Quantity, '<>%1', 0);
                        IF SalesCredLine.FINDSET THEN
                            REPEAT
                                SalesCredLine.TESTFIELD(Quantity);
                                IF SalesCredLine.Type = SalesCredLine.Type::Item THEN BEGIN
                                    SalesCredLine.TESTFIELD("Unit of Measure Code");

                                END;
                                //IF GSTManagement.IsGSTApplicable(Structure) THEN//HSNFix  //B2BUPG1.0
                                SalesCredLine.TESTFIELD("HSN/SAC Code");
                            UNTIL SalesCredLine.NEXT = 0;
                    END;
                END;
        END;
    end;

    procedure CheckCancelIRNValidaitons(Variant: Variant);
    var
        SalesInvHead: Record "Sales Invoice Header";
        SalesCrdHead: Record "Sales Cr.Memo Header";
        ValidTo: DateTime;
        RecRef: RecordRef;
        EInvoiceEntry: Record "E-Invoice Entry";
        TransferShipmentHeader: Record "Transfer Shipment Header";
    begin
        CheckGSTEInvSetup;
        RecRef.GETTABLE(Variant);
        CASE RecRef.NUMBER OF
            112:
                BEGIN
                    SalesInvHead := Variant;
                    EInvoiceEntry.GET(EInvoiceEntry."Document Type"::"Sales Invoice", SalesInvHead."No.");
                    EInvoiceEntry.TESTFIELD("IRN Cancelled", FALSE);
                    ValidTo := CREATEDATETIME(CALCDATE('1D', DT2DATE(EInvoiceEntry."Ack Date")), DT2TIME(EInvoiceEntry."Ack Date"));
                    IF ValidTo < CURRENTDATETIME THEN
                        ERROR(CancelValidToErr);

                    IF CheckCrMemoActiveApplicationExist(SalesInvHead) THEN
                        ERROR(CrMemoAppliedErr);
                END;
            114:
                BEGIN
                    SalesCrdHead := Variant;
                    EInvoiceEntry.GET(EInvoiceEntry."Document Type"::"Sales Cr. Memo", SalesCrdHead."No.");
                    EInvoiceEntry.TESTFIELD("IRN Cancelled", FALSE);
                    ValidTo := CREATEDATETIME(CALCDATE('1D', DT2DATE(EInvoiceEntry."Ack Date")), DT2TIME(EInvoiceEntry."Ack Date"));
                    IF ValidTo < CURRENTDATETIME THEN
                        ERROR(CancelValidToErr);
                END;
            5744:
                BEGIN
                    TransferShipmentHeader := Variant;
                    EInvoiceEntry.GET(EInvoiceEntry."Document Type"::"Transfer Shipment", TransferShipmentHeader."No.");
                    EInvoiceEntry.TESTFIELD("IRN Cancelled", FALSE);
                    ValidTo := CREATEDATETIME(CALCDATE('1D', DT2DATE(EInvoiceEntry."Ack Date")), DT2TIME(EInvoiceEntry."Ack Date"));
                    IF ValidTo < CURRENTDATETIME THEN
                        ERROR(CancelValidToErr);
                END;
        END;
    end;

    local procedure GetInvRoundingAcc(Variant: Variant): Code[20];
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        RecRef: RecordRef;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        RecRef.GETTABLE(Variant);
        CASE RecRef.NUMBER OF
            36:
                BEGIN
                    SalesHeader := Variant;
                    IF SalesHeader."Customer Posting Group" <> '' THEN
                        CustomerPostingGroup.GET(SalesHeader."Customer Posting Group");
                END;
            112:
                BEGIN
                    SalesInvoiceHeader := Variant;
                    IF SalesInvoiceHeader."Customer Posting Group" <> '' THEN
                        CustomerPostingGroup.GET(SalesInvoiceHeader."Customer Posting Group");
                END;
            114:
                BEGIN
                    SalesCrMemoHeader := Variant;
                    IF SalesCrMemoHeader."Customer Posting Group" <> '' THEN
                        CustomerPostingGroup.GET(SalesCrMemoHeader."Customer Posting Group");
                END;
        END;
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

    procedure CheckValidEntriesApplied(SalesHeader: Record "Sales Header");
    var
        ReferenceInvoiceNo: Record "Reference Invoice No.";
        SalesInvHdr: Record "Sales Invoice Header";
        ActiveInvoice: Boolean;
        InActiveInvoice: Boolean;
        EInvoiceEntry: Record "E-Invoice Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        IF SalesHeader."Document Type" <> SalesHeader."Document Type"::"Credit Memo" THEN
            EXIT;

        ReferenceInvoiceNo.SETRANGE("Document Type", SalesHeader."Document Type".AsInteger());
        ReferenceInvoiceNo.SETRANGE("Document No.", SalesHeader."No.");
        ReferenceInvoiceNo.SETRANGE("Source No.", SalesHeader."Bill-to Customer No.");
        ReferenceInvoiceNo.SETRANGE("Source Type", ReferenceInvoiceNo."Source Type"::Customer);
        IF ReferenceInvoiceNo.FINDSET THEN
            REPEAT
                SalesInvHdr.GET(ReferenceInvoiceNo."Reference Invoice Nos.");
                IF SalesInvHdr."Posting Date" >= DMY2DATE(1, 10, 2020) THEN BEGIN//Fix 01Oct2020
                    EInvoiceEntry.GET(EInvoiceEntry."Document Type"::"Sales Invoice", SalesInvHdr."No.");
                    IF NOT ActiveInvoice THEN
                        ActiveInvoice := NOT EInvoiceEntry."IRN Cancelled";
                    IF NOT InActiveInvoice THEN
                        InActiveInvoice := EInvoiceEntry."IRN Cancelled";
                END;
            UNTIL (ReferenceInvoiceNo.NEXT = 0) OR (ActiveInvoice AND InActiveInvoice);

        //>>2016CU19
        // IF (SalesHeader."Applies-to Doc. Type" = SalesHeader."Applies-to Doc. Type"::Invoice) AND
        //  (SalesHeader."Applies-to Doc. No." <> '')
        // THEN BEGIN
        //  SalesInvHdr.GET(SalesHeader."Applies-to Doc. No.");
        //  EInvoiceEntry.GET(EInvoiceEntry."Document Type"::"Sales Invoice",SalesInvHdr."No.");
        //  IF NOT ActiveInvoice THEN
        //    ActiveInvoice := NOT EInvoiceEntry."IRN Cancelled";
        //  IF NOT InActiveInvoice THEN
        //    InActiveInvoice := EInvoiceEntry."IRN Cancelled";
        // END ELSE IF SalesHeader."Applies-to ID" <> '' THEN BEGIN
        //  CustLedgEntry.RESET;
        //  CustLedgEntry.SETCURRENTKEY("Customer No.",Open);
        //  CustLedgEntry.SETRANGE("Customer No.",SalesHeader."Bill-to Customer No.");
        //  CustLedgEntry.SETRANGE(Open,TRUE);
        //  CustLedgEntry.SETRANGE("Applies-to ID",SalesHeader."Applies-to ID");
        //  IF CustLedgEntry.FINDSET THEN
        //    REPEAT
        //      IF SalesInvHdr.GET(CustLedgEntry."Document No.") THEN
        //          IF SalesInvHdr."Posting Date" >= DMY2DATE(1,10,2020) THEN BEGIN//Fix 01Oct2020
        //            EInvoiceEntry.GET(EInvoiceEntry."Document Type"::"Sales Invoice",SalesInvHdr."No.");
        //            IF NOT ActiveInvoice THEN
        //              ActiveInvoice := NOT EInvoiceEntry."IRN Cancelled";
        //            IF NOT InActiveInvoice THEN
        //              InActiveInvoice := EInvoiceEntry."IRN Cancelled";
        //          END;
        //    UNTIL (CustLedgEntry.NEXT = 0) OR (ActiveInvoice AND InActiveInvoice);
        // END;
        //<<2016CU19
        IF ActiveInvoice AND InActiveInvoice THEN
            ERROR(ActiveInActiveInvErr);
    end;

    local procedure CheckCrMemoActiveApplicationExist(SalesInvHdr: Record "Sales Invoice Header"): Boolean;
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ActiveApplicationFound: Boolean;
        EInvoiceEntry: Record "E-Invoice Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        AppliedCustLedgEntry: Record "Cust. Ledger Entry";
    begin
        WITH CustLedgerEntry DO BEGIN
            SETRANGE("Document No.", SalesInvHdr."No.");
            SETRANGE("Posting Date", SalesInvHdr."Posting Date");
            FINDFIRST;

            FindApplnEntriesDtldtLedgEntry(CustLedgerEntry, AppliedCustLedgEntry);
            AppliedCustLedgEntry.MARKEDONLY(TRUE);
            IF AppliedCustLedgEntry.FINDSET THEN
                REPEAT
                    IF SalesCrMemoHeader.GET(AppliedCustLedgEntry."Document No.") THEN BEGIN
                        EInvoiceEntry.GET(EInvoiceEntry."Document Type"::"Sales Cr. Memo", SalesCrMemoHeader."No.");
                        ActiveApplicationFound := (NOT EInvoiceEntry."IRN Cancelled");
                    END;
                UNTIL (AppliedCustLedgEntry.NEXT = 0) OR ActiveApplicationFound;
        END;

        EXIT(ActiveApplicationFound);
    end;

    procedure IsInActiveInvoiceApplied(SalesCrMemoHeader: Record "Sales Cr.Memo Header"): Boolean;
    var
        ReferenceInvoiceNo: Record "Reference Invoice No.";
        SalesInvHdr: Record "Sales Invoice Header";
        ActiveInvoice: Boolean;
        InActiveInvoice: Boolean;
        EInvoiceEntry: Record "E-Invoice Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        AppliedCustLedgEntry: Record "Cust. Ledger Entry";
    begin
        ReferenceInvoiceNo.SETRANGE("Document No.", SalesCrMemoHeader."No.");
        IF ReferenceInvoiceNo.FINDSET THEN
            REPEAT
                SalesInvHdr.GET(ReferenceInvoiceNo."Reference Invoice Nos.");
                IF SalesInvHdr."Posting Date" >= DMY2DATE(1, 10, 2020) THEN BEGIN//Fix 01Oct2020
                    EInvoiceEntry.GET(EInvoiceEntry."Document Type"::"Sales Invoice", SalesInvHdr."No.");
                    InActiveInvoice := (EInvoiceEntry."IRN No." = '') OR EInvoiceEntry."IRN Cancelled";
                END;
            UNTIL (ReferenceInvoiceNo.NEXT = 0) OR InActiveInvoice
        ELSE
            WITH CustLedgerEntry DO BEGIN
                SETRANGE("Document No.", SalesCrMemoHeader."No.");
                SETRANGE("Posting Date", SalesCrMemoHeader."Posting Date");
                FINDFIRST;

                FindApplnEntriesDtldtLedgEntry(CustLedgerEntry, AppliedCustLedgEntry);
                AppliedCustLedgEntry.MARKEDONLY(TRUE);
                IF AppliedCustLedgEntry.FINDSET THEN
                    REPEAT
                        IF SalesInvHdr.GET(AppliedCustLedgEntry."Document No.") THEN
                            IF SalesInvHdr."Posting Date" >= DMY2DATE(1, 10, 2020) THEN BEGIN//Fix 01Oct2020
                                EInvoiceEntry.GET(EInvoiceEntry."Document Type"::"Sales Invoice", SalesInvHdr."No.");
                                InActiveInvoice := (EInvoiceEntry."IRN No." = '') OR EInvoiceEntry."IRN Cancelled";
                            END;
                    UNTIL (AppliedCustLedgEntry.NEXT = 0) OR InActiveInvoice;
            END;

        EXIT(InActiveInvoice);
    end;

    local procedure FindApplnEntriesDtldtLedgEntry(CreateCustLedgEntry: Record "Cust. Ledger Entry"; var AppliedCustLedgEntry: Record "Cust. Ledger Entry");
    var
        DtldCustLedgEntry1: Record "Detailed Cust. Ledg. Entry";
        DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
    begin
        WITH AppliedCustLedgEntry DO BEGIN
            DtldCustLedgEntry1.SETCURRENTKEY("Cust. Ledger Entry No.");
            DtldCustLedgEntry1.SETRANGE("Cust. Ledger Entry No.", CreateCustLedgEntry."Entry No.");
            DtldCustLedgEntry1.SETRANGE(Unapplied, FALSE);
            IF DtldCustLedgEntry1.FIND('-') THEN
                REPEAT
                    IF DtldCustLedgEntry1."Cust. Ledger Entry No." =
                       DtldCustLedgEntry1."Applied Cust. Ledger Entry No."
                    THEN BEGIN
                        DtldCustLedgEntry2.INIT;
                        DtldCustLedgEntry2.SETCURRENTKEY("Applied Cust. Ledger Entry No.", "Entry Type");
                        DtldCustLedgEntry2.SETRANGE(
                          "Applied Cust. Ledger Entry No.", DtldCustLedgEntry1."Applied Cust. Ledger Entry No.");
                        DtldCustLedgEntry2.SETRANGE("Entry Type", DtldCustLedgEntry2."Entry Type"::Application);
                        DtldCustLedgEntry2.SETRANGE(Unapplied, FALSE);
                        IF DtldCustLedgEntry2.FIND('-') THEN
                            REPEAT
                                IF DtldCustLedgEntry2."Cust. Ledger Entry No." <>
                                   DtldCustLedgEntry2."Applied Cust. Ledger Entry No."
                                THEN BEGIN
                                    SETCURRENTKEY("Entry No.");
                                    SETRANGE("Entry No.", DtldCustLedgEntry2."Cust. Ledger Entry No.");
                                    IF FIND('-') THEN
                                        MARK(TRUE);
                                END;
                            UNTIL DtldCustLedgEntry2.NEXT = 0;
                    END ELSE BEGIN
                        SETCURRENTKEY("Entry No.");
                        SETRANGE("Entry No.", DtldCustLedgEntry1."Applied Cust. Ledger Entry No.");
                        IF FIND('-') THEN
                            MARK(TRUE);
                    END;
                UNTIL DtldCustLedgEntry1.NEXT = 0;
        END;
    end;

    procedure CheckGenerateIRNValidaitons(Variant: Variant);
    var
        SalesInvHead: Record "Sales Invoice Header";
        SalesCrdHead: Record "Sales Cr.Memo Header";
        ValidTo: DateTime;
        RecRef: RecordRef;
        EInvoiceEntry: Record "E-Invoice Entry";
    begin
        //>> ValidIRNFix
        RecRef.GETTABLE(Variant);
        CASE RecRef.NUMBER OF
            112:
                BEGIN
                    SalesInvHead := Variant;
                    IF CheckCrMemoApplicationExist(SalesInvHead) THEN
                        ERROR(CrMemoAppliedErr2);
                END;
            114:
                BEGIN
                    SalesCrdHead := Variant;
                    IF IsInActiveInvoiceApplied(SalesCrdHead) THEN
                        ERROR(InActiveInvAppliedErr);
                END;
        END;
        //<< ValidIRNFix
    end;

    local procedure CheckCrMemoApplicationExist(SalesInvHdr: Record "Sales Invoice Header"): Boolean;
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ApplicationFound: Boolean;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        AppliedCustLedgEntry: Record "Cust. Ledger Entry";
    begin
        //>> ValidIRNFix
        WITH CustLedgerEntry DO BEGIN
            SETRANGE("Document No.", SalesInvHdr."No.");
            SETRANGE("Posting Date", SalesInvHdr."Posting Date");
            FINDFIRST;

            FindApplnEntriesDtldtLedgEntry(CustLedgerEntry, AppliedCustLedgEntry);
            AppliedCustLedgEntry.MARKEDONLY(TRUE);
            IF AppliedCustLedgEntry.FINDSET THEN
                REPEAT
                    ApplicationFound := SalesCrMemoHeader.GET(AppliedCustLedgEntry."Document No.");
                UNTIL (AppliedCustLedgEntry.NEXT = 0) OR ApplicationFound;
        END;

        EXIT(ApplicationFound);
        //<< ValidIRNFix
    end;

    procedure GetNumberFilter(Variant: Variant) ReturnValue: Text
    var
        DefferedOrderSetup: Record 50007;
        RecRef: RecordRef;
        SalesHeader: Record 36;
        SalesInvoiceHeader: Record 112;
        SalesCrMemoHeader: Record 114;
        NumberArr: array[5] of Code[20];
        i: Integer;
    begin
        RecRef.GETTABLE(Variant);
        CASE RecRef.NUMBER OF
            36:
                BEGIN
                    SalesHeader := Variant;
                    IF SalesHeader."Sales Type" = '' THEN
                        EXIT('');
                    DefferedOrderSetup.GET(SalesHeader."Sales Type");
                END;
            112:
                BEGIN
                    SalesInvoiceHeader := Variant;
                    IF SalesInvoiceHeader."Sales Type" = '' THEN
                        EXIT('');
                    DefferedOrderSetup.GET(SalesInvoiceHeader."Sales Type");
                END;
            114:
                BEGIN
                    SalesCrMemoHeader := Variant;
                    IF SalesCrMemoHeader."Sales Type" = '' THEN
                        EXIT('');
                    DefferedOrderSetup.GET(SalesCrMemoHeader."Sales Type");
                END;
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
}

