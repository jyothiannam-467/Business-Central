tableextension 50118 CustomerExt extends Customer
{
    fields
    {
        field(50100; "ZY Thumbnail"; BLOB)
        {
            Caption = 'Thumbnail';
            SubType = Bitmap;
        }
    }
}
pageextension 50118 CustomerListExt extends "Customer List"
{
    layout
    {
        addafter(Name)
        {
            field(Thumbnail; Rec."ZY Thumbnail")
            {
                ApplicationArea = All;
            }
        }
    }
    actions
    {
        addafter(ApplyTemplate)
        {
            action(UpdatePictureThumbnails)
            {
                Caption = 'Update Picture Thumbnails';
                Promoted = true;
                PromotedCategory = Process;
                Image = UpdateDescription;
                ApplicationArea = All;
                trigger OnAction()
                var
                    TenantMedia: Record "Tenant Media";
                begin
                    if Rec.FindSet() then
                        repeat
                            if TenantMedia.Get(Rec.Image.MediaId) then begin
                                TenantMedia.CalcFields(Content);
                                Rec."ZY Thumbnail" := TenantMedia.Content;
                                Rec.Modify(true);
                            end else begin
                                if Rec."ZY Thumbnail".HasValue then begin
                                    Rec.CalcFields("ZY Thumbnail");
                                    Clear(Rec."ZY Thumbnail");
                                    Rec.Modify(true);
                                end;
                            end;
                        until Rec.Next() = 0;
                    Rec.FindFirst();
                end;
            }
        }
    }
}
