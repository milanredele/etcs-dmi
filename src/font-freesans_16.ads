package Font.FreeSans_16 is

   Glyphs : Glyph_Map := ('0' => (Left => 1,
                                  Top => 16,
                                  Advance_X => 12,
                                  Height => 16,
                                  Width => 10,
                                  Bitmap_Pos => 1
                                 ),
                          '1' => (Left => 2,
                                  Top => 16,
                                  Advance_X => 12,
                                  Height => 16,
                                  Width => 6,
                                  Bitmap_Pos => 161
                                 ),
                          '2' => (Left => 1,
                                  Top => 16,
                                  Advance_X => 12,
                                  Height => 16,
                                  Width => 10,
                                  Bitmap_Pos => 257
                                 ),
                          '3' => (Left => 1,
                                  Top => 16,
                                  Advance_X => 12,
                                  Height => 16,
                                  Width => 10,
                                  Bitmap_Pos => 417
                                 ),
                          '4' => (Left => 1,
                                  Top => 16,
                                  Advance_X => 12,
                                  Height => 16,
                                  Width => 11,
                                  Bitmap_Pos => 577
                                 ),
                          '5' => (Left => 1,
                                  Top => 16,
                                  Advance_X => 12,
                                  Height => 16,
                                  Width => 10,
                                  Bitmap_Pos => 753
                                 ),
                          '6' => (Left => 1,
                                  Top => 16,
                                  Advance_X => 12,
                                  Height => 16,
                                  Width => 10,
                                  Bitmap_Pos => 913
                                 ),
                          '7' => (Left => 1,
                                  Top => 16,
                                  Advance_X => 12,
                                  Height => 16,
                                  Width => 11,
                                  Bitmap_Pos => 1073
                                 ),
                          '8' => (Left => 1,
                                  Top => 16,
                                  Advance_X => 12,
                                  Height => 16,
                                  Width => 10,
                                  Bitmap_Pos => 1249
                                 ),
                          '9' => (Left => 1,
                                  Top => 16,
                                  Advance_X => 12,
                                  Height => 16,
                                  Width => 10,
                                  Bitmap_Pos => 1409
                                 ));

   Bitmap : Bitmap_T 
     := (
         -- codepoint 0X30
         False,False,False,True ,True ,True ,True ,False,False,False, --    ****   
         False,False,True ,True ,True ,True ,True ,True ,True ,False, --   ******* 
         False,True ,True ,False,False,False,False,True ,True ,False, --  **    ** 
         False,True ,True ,False,False,False,False,False,True ,True , --  **     **
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         False,True ,True ,False,False,False,False,False,True ,True , --  **     **
         False,True ,True ,False,False,False,False,True ,True ,False, --  **    ** 
         False,False,True ,True ,True ,True ,True ,True ,True ,False, --   ******* 
         False,False,False,True ,True ,True ,True ,False,False,False, --    ****   
         -- codepoint 0X31
         False,False,False,False,True ,True , --     **
         False,False,False,False,True ,True , --     **
         False,False,False,True ,True ,True , --    ***
         True ,True ,True ,True ,True ,True , -- ******
         False,False,False,False,True ,True , --     **
         False,False,False,False,True ,True , --     **
         False,False,False,False,True ,True , --     **
         False,False,False,False,True ,True , --     **
         False,False,False,False,True ,True , --     **
         False,False,False,False,True ,True , --     **
         False,False,False,False,True ,True , --     **
         False,False,False,False,True ,True , --     **
         False,False,False,False,True ,True , --     **
         False,False,False,False,True ,True , --     **
         False,False,False,False,True ,True , --     **
         False,False,False,False,True ,True , --     **
         -- codepoint 0X32
         False,False,False,True ,True ,True ,True ,True ,False,False, --    *****  
         False,True ,True ,True ,True ,True ,True ,True ,True ,False, --  ******** 
         False,True ,True ,False,False,False,False,True ,True ,True , --  **    ***
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         False,False,False,False,False,False,False,False,True ,True , --         **
         False,False,False,False,False,False,False,True ,True ,False, --        ** 
         False,False,False,False,False,True ,True ,True ,True ,False, --      **** 
         False,False,False,True ,True ,True ,True ,False,False,False, --    ****   
         False,False,True ,True ,True ,False,False,False,False,False, --   ***     
         False,True ,True ,True ,False,False,False,False,False,False, --  ***      
         True ,True ,True ,False,False,False,False,False,False,False, -- ***       
         True ,True ,False,False,False,False,False,False,False,False, -- **        
         True ,True ,True ,True ,True ,True ,True ,True ,True ,True , -- **********
         True ,True ,True ,True ,True ,True ,True ,True ,True ,True , -- **********
         -- codepoint 0X33
         False,False,True ,True ,True ,True ,True ,False,False,False, --   *****   
         False,True ,True ,True ,True ,True ,True ,True ,True ,False, --  ******** 
         False,True ,True ,False,False,False,False,True ,True ,False, --  **    ** 
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         False,False,False,False,False,False,False,False,True ,True , --         **
         False,False,False,False,False,False,False,True ,True ,False, --        ** 
         False,False,False,False,True ,True ,True ,True ,False,False, --     ****  
         False,False,False,False,True ,True ,True ,True ,True ,False, --     ***** 
         False,False,False,False,False,False,False,False,True ,True , --         **
         False,False,False,False,False,False,False,False,True ,True , --         **
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         True ,True ,True ,False,False,False,False,True ,True ,True , -- ***    ***
         False,True ,True ,True ,True ,True ,True ,True ,True ,False, --  ******** 
         False,False,True ,True ,True ,True ,True ,True ,False,False, --   ******  
         -- codepoint 0X34
         False,False,False,False,False,False,True ,True ,False,False,False, --       **   
         False,False,False,False,False,False,True ,True ,False,False,False, --       **   
         False,False,False,False,False,True ,True ,True ,False,False,False, --      ***   
         False,False,False,False,True ,True ,True ,True ,False,False,False, --     ****   
         False,False,False,False,True ,False,True ,True ,False,False,False, --     * **   
         False,False,False,True ,True ,False,True ,True ,False,False,False, --    ** **   
         False,False,True ,True ,False,False,True ,True ,False,False,False, --   **  **   
         False,True ,True ,False,False,False,True ,True ,False,False,False, --  **   **   
         False,True ,True ,False,False,False,True ,True ,False,False,False, --  **   **   
         True ,True ,False,False,False,False,True ,True ,False,False,False, -- **    **   
         True ,True ,True ,True ,True ,True ,True ,True ,True ,True ,True , -- ***********
         True ,True ,True ,True ,True ,True ,True ,True ,True ,True ,True , -- ***********
         False,False,False,False,False,False,True ,True ,False,False,False, --       **   
         False,False,False,False,False,False,True ,True ,False,False,False, --       **   
         False,False,False,False,False,False,True ,True ,False,False,False, --       **   
         False,False,False,False,False,False,True ,True ,False,False,False, --       **   
         -- codepoint 0X35
         False,True ,True ,True ,True ,True ,True ,True ,True ,True , --  *********
         False,True ,True ,True ,True ,True ,True ,True ,True ,True , --  *********
         False,True ,True ,False,False,False,False,False,False,False, --  **       
         False,True ,True ,False,False,False,False,False,False,False, --  **       
         False,True ,True ,False,False,False,False,False,False,False, --  **       
         False,True ,False,False,True ,True ,True ,False,False,False, --  *  ***   
         False,True ,True ,True ,True ,True ,True ,True ,True ,False, --  ******** 
         True ,True ,True ,False,False,False,False,True ,True ,True , -- ***    ***
         False,False,False,False,False,False,False,False,True ,True , --         **
         False,False,False,False,False,False,False,False,True ,True , --         **
         False,False,False,False,False,False,False,False,True ,True , --         **
         False,False,False,False,False,False,False,False,True ,True , --         **
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         True ,True ,True ,False,False,False,False,True ,True ,True , -- ***    ***
         False,True ,True ,True ,True ,True ,True ,True ,True ,False, --  ******** 
         False,False,True ,True ,True ,True ,True ,False,False,False, --   *****   
         -- codepoint 0X36
         False,False,False,True ,True ,True ,True ,True ,False,False, --    *****  
         False,False,True ,True ,True ,True ,True ,True ,True ,False, --   ******* 
         False,True ,True ,False,False,False,False,True ,True ,True , --  **    ***
         False,True ,True ,False,False,False,False,False,True ,True , --  **     **
         True ,True ,False,False,False,False,False,False,False,False, -- **        
         True ,True ,False,False,False,False,False,False,False,False, -- **        
         True ,True ,False,True ,True ,True ,True ,True ,False,False, -- ** *****  
         True ,True ,True ,True ,True ,True ,True ,True ,True ,False, -- ********* 
         True ,True ,True ,False,False,False,False,True ,True ,True , -- ***    ***
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         False,True ,True ,False,False,False,False,True ,True ,True , --  **    ***
         False,False,True ,True ,True ,True ,True ,True ,True ,False, --   ******* 
         False,False,False,True ,True ,True ,True ,True ,False,False, --    *****  
         -- codepoint 0X37
         True ,True ,True ,True ,True ,True ,True ,True ,True ,True ,True , -- ***********
         True ,True ,True ,True ,True ,True ,True ,True ,True ,True ,True , -- ***********
         False,False,False,False,False,False,False,False,True ,True ,False, --         ** 
         False,False,False,False,False,False,False,True ,True ,False,False, --        **  
         False,False,False,False,False,False,False,True ,True ,False,False, --        **  
         False,False,False,False,False,False,True ,True ,False,False,False, --       **   
         False,False,False,False,False,False,True ,False,False,False,False, --       *    
         False,False,False,False,False,True ,True ,False,False,False,False, --      **    
         False,False,False,False,False,True ,False,False,False,False,False, --      *     
         False,False,False,False,True ,True ,False,False,False,False,False, --     **     
         False,False,False,False,True ,True ,False,False,False,False,False, --     **     
         False,False,False,True ,True ,False,False,False,False,False,False, --    **      
         False,False,False,True ,True ,False,False,False,False,False,False, --    **      
         False,False,False,True ,True ,False,False,False,False,False,False, --    **      
         False,False,True ,True ,False,False,False,False,False,False,False, --   **       
         False,False,True ,True ,False,False,False,False,False,False,False, --   **       
         -- codepoint 0X38
         False,False,False,True ,True ,True ,True ,True ,False,False, --    *****  
         False,True ,True ,True ,True ,True ,True ,True ,True ,False, --  ******** 
         False,True ,True ,False,False,False,False,True ,True ,True , --  **    ***
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         False,True ,True ,False,False,False,False,True ,True ,True , --  **    ***
         False,False,True ,True ,True ,True ,True ,True ,True ,False, --   ******* 
         False,False,True ,True ,True ,True ,True ,True ,False,False, --   ******  
         False,True ,True ,False,False,False,False,True ,True ,True , --  **    ***
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         True ,True ,True ,False,False,False,False,True ,True ,True , -- ***    ***
         False,True ,True ,True ,True ,True ,True ,True ,True ,False, --  ******** 
         False,False,False,True ,True ,True ,True ,True ,False,False, --    *****  
         -- codepoint 0X39
         False,False,False,True ,True ,True ,True ,False,False,False, --    ****   
         False,True ,True ,True ,True ,True ,True ,True ,True ,False, --  ******** 
         False,True ,True ,False,False,False,False,True ,True ,False, --  **    ** 
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         True ,True ,False,False,False,False,False,False,True ,True , -- **      **
         True ,True ,True ,False,False,False,False,True ,True ,True , -- ***    ***
         False,True ,True ,True ,True ,True ,True ,True ,True ,True , --  *********
         False,False,True ,True ,True ,True ,True ,False,True ,True , --   ***** **
         False,False,False,False,False,False,False,False,True ,True , --         **
         False,False,False,False,False,False,False,False,True ,True , --         **
         True ,True ,False,False,False,False,False,True ,True ,True , -- **     ***
         False,True ,True ,False,False,False,False,True ,True ,False, --  **    ** 
         False,True ,True ,True ,True ,True ,True ,True ,False,False, --  *******  
         False,False,True ,True ,True ,True ,True ,False,False,False  --   *****   
        );
end;
