tableextension 50112 CustomerExt extends Customer
{
    fields
    {
        field(50100; RichText; Blob)
        {
            Caption = 'Rich Text';
            DataClassification = CustomerContent;
        }
    }
}
pageextension 50100 CustomerCardExt extends "Customer Card"
{
    layout
    {
        addafter(General)
        {
            group(RichTextGroup)
            {
                Caption = 'Rich Text Group';
                field(RichText; RichTextVar)
                {
                    Caption = 'Rich Text';
                    MultiLine = true;
                    ExtendedDatatype = RichContent;
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        SetRichText();
                    end;
                }
            }
        }
    }

    actions
    {
        addafter(Contact)
        {
            action(PrintRichText)
            {
                Caption = 'Print Rich Text';
                ApplicationArea = All;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    Report.Run(Report::"Rich Text Content", true, false, Rec);
                end;
            }
        }
    }
    var
        RichTextVar: Text;

    trigger OnAfterGetRecord()
    begin
        GetRichText();
    end;

    local procedure GetRichText()
    var
        RichTextInS: InStream;
    begin
        Rec.CalcFields(RichText);
        Rec.RichText.CreateInStream(RichTextInS, TextEncoding::UTF8);
        RichTextInS.Read(RichTextVar);
    end;

    local procedure SetRichText()
    var
        RichTextOutS: OutStream;
    begin
        Rec.RichText.CreateOutStream(RichTextOutS, TextEncoding::UTF8);
        RichTextOutS.Write(RichTextVar);
        Rec.Modify(true);
    end;
}

report 50111 "Rich Text Content"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultRenderingLayout = RichTextContent;

    dataset
    {
        dataitem(Customer; Customer)
        {
            column(No_; "No.")
            {
            }
            column(Name; Name)
            {
            }
            column(RichTextVar; RichTextVar)
            {
            }

            trigger OnAfterGetRecord()
            var
                RichTextInS: InStream;
            begin
                Customer.CalcFields(RichText);
                Customer.RichText.CreateInStream(RichTextInS, TextEncoding::UTF8);
                RichTextInS.Read(RichTextVar);
            end;
        }
    }

    rendering
    {
        layout(RichTextContent)
        {
            Type = RDLC;
            LayoutFile = 'RichTextContent.rdl';
        }
    }

    var
        RichTextVar: Text;
}
