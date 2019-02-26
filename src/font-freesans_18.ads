package Font.FreeSans_18 is
   Face : constant Face_T := (Ascender => 900, Descender => -200, Max_Advance_Width => 2256, Cap_Height => 18);

   type Chars is ('0','1','2','3','4','5','6','7','8','9');

   type Glyph_Array is array (Chars) of Glyph;

   Glyphs : Glyph_Array := ('0' => (Left => 1,
                                    Top => 18,
                                    Advance_X => 14,
                                    Height => 18,
                                    Width => 12,
                                    Pitch => 2,
                                    Bitmap_Pos => 1
                                   ),
                            '1' => (Left => 5,
                                    Top => 18,
                                    Advance_X => 14,
                                    Height => 18,
                                    Width => 6,
                                    Pitch => 2,
                                    Bitmap_Pos => 217
                                   ),
                            '2' => (Left => 1,
                                    Top => 18,
                                    Advance_X => 14,
                                    Height => 18,
                                    Width => 12,
                                    Pitch => 2,
                                    Bitmap_Pos => 325
                                   ),
                            '3' => (Left => 1,
                                    Top => 18,
                                    Advance_X => 14,
                                    Height => 18,
                                    Width => 12,
                                    Pitch => 2,
                                    Bitmap_Pos => 541
                                   ),
                            '4' => (Left => 1,
                                    Top => 18,
                                    Advance_X => 14,
                                    Height => 18,
                                    Width => 12,
                                    Pitch => 2,
                                    Bitmap_Pos => 757
                                   ),
                            '5' => (Left => 1,
                                    Top => 18,
                                    Advance_X => 14,
                                    Height => 18,
                                    Width => 12,
                                    Pitch => 2,
                                    Bitmap_Pos => 973
                                   ),
                            '6' => (Left => 1,
                                    Top => 18,
                                    Advance_X => 14,
                                    Height => 18,
                                    Width => 12,
                                    Pitch => 2,
                                    Bitmap_Pos => 1189
                                   ),
                            '7' => (Left => 1,
                                    Top => 18,
                                    Advance_X => 14,
                                    Height => 18,
                                    Width => 12,
                                    Pitch => 2,
                                    Bitmap_Pos => 1405
                                   ),
                            '8' => (Left => 1,
                                    Top => 18,
                                    Advance_X => 14,
                                    Height => 18,
                                    Width => 12,
                                    Pitch => 2,
                                    Bitmap_Pos => 1621
                                   ),
                            '9' => (Left => 1,
                                    Top => 18,
                                    Advance_X => 14,
                                    Height => 18,
                                    Width => 12,
                                    Pitch => 2,
                                    Bitmap_Pos => 1837
                                   ));

   Bitmap : Bitmap_T 
     := (
         -- codepoint 0X30
         False,False,False,False,True ,True ,True ,True ,False,False,False,False, --     ****    
         False,False,True ,True ,True ,True ,True ,True ,True ,True ,False,False, --   ********  
         False,True ,True ,True ,False,False,False,False,True ,True ,False,False, --  ***    **  
         False,True ,True ,False,False,False,False,False,True ,True ,True ,False, --  **     *** 
         False,True ,True ,False,False,False,False,False,False,True ,True ,False, --  **      ** 
         True ,True ,True ,False,False,False,False,False,False,True ,True ,False, -- ***      ** 
         True ,True ,False,False,False,False,False,False,False,True ,True ,True , -- **       ***
         True ,True ,False,False,False,False,False,False,False,True ,True ,True , -- **       ***
         True ,True ,False,False,False,False,False,False,False,True ,True ,True , -- **       ***
         True ,True ,False,False,False,False,False,False,False,True ,True ,True , -- **       ***
         True ,True ,False,False,False,False,False,False,False,True ,True ,True , -- **       ***
         True ,True ,False,False,False,False,False,False,False,True ,True ,True , -- **       ***
         True ,True ,True ,False,False,False,False,False,False,True ,True ,False, -- ***      ** 
         False,True ,True ,False,False,False,False,False,False,True ,True ,False, --  **      ** 
         False,True ,True ,False,False,False,False,False,False,True ,True ,False, --  **      ** 
         False,True ,True ,True ,False,False,False,False,True ,True ,False,False, --  ***    **  
         False,False,True ,True ,True ,True ,True ,True ,True ,True ,False,False, --   ********  
         False,False,False,False,True ,True ,True ,True ,False,False,False,False, --     ****    
         -- codepoint 0X31
         False,False,False,False,True ,True , --     **
         False,False,False,False,True ,True , --     **
         False,False,False,True ,True ,True , --    ***
         True ,True ,True ,True ,True ,True , -- ******
         True ,True ,True ,True ,True ,True , -- ******
         False,False,False,True ,True ,True , --    ***
         False,False,False,True ,True ,True , --    ***
         False,False,False,True ,True ,True , --    ***
         False,False,False,True ,True ,True , --    ***
         False,False,False,True ,True ,True , --    ***
         False,False,False,True ,True ,True , --    ***
         False,False,False,True ,True ,True , --    ***
         False,False,False,True ,True ,True , --    ***
         False,False,False,True ,True ,True , --    ***
         False,False,False,True ,True ,True , --    ***
         False,False,False,True ,True ,True , --    ***
         False,False,False,True ,True ,True , --    ***
         False,False,False,True ,True ,True , --    ***
         -- codepoint 0X32
         False,False,False,True ,True ,True ,True ,True ,True ,False,False,False, --    ******   
         False,False,True ,True ,True ,True ,True ,True ,True ,True ,False,False, --   ********  
         False,True ,True ,True ,False,False,False,False,True ,True ,True ,False, --  ***    *** 
         False,True ,True ,False,False,False,False,False,False,True ,True ,True , --  **      ***
         True ,True ,True ,False,False,False,False,False,False,True ,True ,True , -- ***      ***
         True ,True ,True ,False,False,False,False,False,False,False,True ,True , -- ***       **
         False,False,False,False,False,False,False,False,False,True ,True ,True , --          ***
         False,False,False,False,False,False,False,False,False,True ,True ,False, --          ** 
         False,False,False,False,False,False,False,False,True ,True ,True ,False, --         *** 
         False,False,False,False,False,False,True ,True ,True ,True ,False,False, --       ****  
         False,False,False,False,True ,True ,True ,True ,False,False,False,False, --     ****    
         False,False,False,True ,True ,True ,True ,False,False,False,False,False, --    ****     
         False,False,True ,True ,True ,False,False,False,False,False,False,False, --   ***       
         False,True ,True ,True ,False,False,False,False,False,False,False,False, --  ***        
         False,True ,True ,False,False,False,False,False,False,False,False,False, --  **         
         True ,True ,False,False,False,False,False,False,False,False,False,False, -- **          
         True ,True ,True ,True ,True ,True ,True ,True ,True ,True ,True ,True , -- ************
         True ,True ,True ,True ,True ,True ,True ,True ,True ,True ,True ,True , -- ************
         -- codepoint 0X33
         False,False,False,True ,True ,True ,True ,True ,False,False,False,False, --    *****    
         False,False,True ,True ,True ,True ,True ,True ,True ,True ,False,False, --   ********  
         False,True ,True ,True ,False,False,False,False,True ,True ,True ,False, --  ***    *** 
         False,True ,True ,False,False,False,False,False,False,True ,True ,False, --  **      ** 
         True ,True ,True ,False,False,False,False,False,False,True ,True ,False, -- ***      ** 
         True ,True ,False,False,False,False,False,False,False,True ,True ,False, -- **       ** 
         False,False,False,False,False,False,False,False,False,True ,True ,False, --          ** 
         False,False,False,False,False,False,False,False,True ,True ,False,False, --         **  
         False,False,False,False,False,True ,True ,True ,True ,False,False,False, --      ****   
         False,False,False,False,False,True ,True ,True ,True ,True ,False,False, --      *****  
         False,False,False,False,False,False,False,False,True ,True ,True ,False, --         *** 
         False,False,False,False,False,False,False,False,False,True ,True ,True , --          ***
         False,False,False,False,False,False,False,False,False,True ,True ,True , --          ***
         True ,True ,False,False,False,False,False,False,False,True ,True ,True , -- **       ***
         True ,True ,True ,False,False,False,False,False,False,True ,True ,False, -- ***      ** 
         False,True ,True ,False,False,False,False,False,True ,True ,True ,False, --  **     *** 
         False,True ,True ,True ,True ,True ,True ,True ,True ,True ,False,False, --  *********  
         False,False,False,True ,True ,True ,True ,True ,False,False,False,False, --    *****    
         -- codepoint 0X34
         False,False,False,False,False,False,False,True ,True ,False,False,False, --        **   
         False,False,False,False,False,False,False,True ,True ,False,False,False, --        **   
         False,False,False,False,False,False,True ,True ,True ,False,False,False, --       ***   
         False,False,False,False,False,True ,True ,True ,True ,False,False,False, --      ****   
         False,False,False,False,False,True ,True ,True ,True ,False,False,False, --      ****   
         False,False,False,False,True ,True ,False,True ,True ,False,False,False, --     ** **   
         False,False,False,True ,True ,False,False,True ,True ,False,False,False, --    **  **   
         False,False,False,True ,True ,False,False,True ,True ,False,False,False, --    **  **   
         False,False,True ,True ,False,False,False,True ,True ,False,False,False, --   **   **   
         False,True ,True ,False,False,False,False,True ,True ,False,False,False, --  **    **   
         True ,True ,True ,False,False,False,False,True ,True ,False,False,False, -- ***    **   
         True ,True ,False,False,False,False,False,True ,True ,False,False,False, -- **     **   
         True ,True ,True ,True ,True ,True ,True ,True ,True ,True ,True ,True , -- ************
         True ,True ,True ,True ,True ,True ,True ,True ,True ,True ,True ,True , -- ************
         False,False,False,False,False,False,False,True ,True ,False,False,False, --        **   
         False,False,False,False,False,False,False,True ,True ,False,False,False, --        **   
         False,False,False,False,False,False,False,True ,True ,False,False,False, --        **   
         False,False,False,False,False,False,False,True ,True ,False,False,False, --        **   
         -- codepoint 0X35
         False,False,True ,True ,True ,True ,True ,True ,True ,True ,True ,False, --   ********* 
         False,False,True ,True ,True ,True ,True ,True ,True ,True ,True ,False, --   ********* 
         False,True ,True ,False,False,False,False,False,False,False,False,False, --  **         
         False,True ,True ,False,False,False,False,False,False,False,False,False, --  **         
         False,True ,True ,False,False,False,False,False,False,False,False,False, --  **         
         False,True ,True ,False,False,False,False,False,False,False,False,False, --  **         
         False,True ,True ,False,True ,True ,True ,True ,True ,False,False,False, --  ** *****   
         False,True ,True ,True ,True ,True ,True ,True ,True ,True ,False,False, --  *********  
         False,True ,True ,True ,False,False,False,False,True ,True ,True ,False, --  ***    *** 
         True ,True ,False,False,False,False,False,False,False,True ,True ,False, -- **       ** 
         False,False,False,False,False,False,False,False,False,True ,True ,True , --          ***
         False,False,False,False,False,False,False,False,False,False,True ,True , --           **
         False,False,False,False,False,False,False,False,False,False,True ,True , --           **
         True ,True ,False,False,False,False,False,False,False,True ,True ,True , -- **       ***
         True ,True ,True ,False,False,False,False,False,False,True ,True ,False, -- ***      ** 
         False,True ,True ,True ,False,False,False,False,True ,True ,True ,False, --  ***    *** 
         False,True ,True ,True ,True ,True ,True ,True ,True ,True ,False,False, --  *********  
         False,False,False,True ,True ,True ,True ,True ,False,False,False,False, --    *****    
         -- codepoint 0X36
         False,False,False,False,True ,True ,True ,True ,True ,False,False,False, --     *****   
         False,False,False,True ,True ,True ,True ,True ,True ,True ,False,False, --    *******  
         False,False,True ,True ,False,False,False,False,True ,True ,True ,False, --   **    *** 
         False,True ,True ,True ,False,False,False,False,False,True ,True ,False, --  ***     ** 
         False,True ,True ,False,False,False,False,False,False,True ,True ,False, --  **      ** 
         False,True ,True ,False,False,False,False,False,False,False,False,False, --  **         
         True ,True ,True ,False,False,False,False,False,False,False,False,False, -- ***         
         True ,True ,False,False,True ,True ,True ,True ,True ,False,False,False, -- **  *****   
         True ,True ,False,True ,True ,True ,True ,True ,True ,True ,False,False, -- ** *******  
         True ,True ,True ,True ,False,False,False,False,True ,True ,True ,False, -- ****    *** 
         True ,True ,True ,False,False,False,False,False,False,True ,True ,True , -- ***      ***
         True ,True ,True ,False,False,False,False,False,False,True ,True ,True , -- ***      ***
         True ,True ,False,False,False,False,False,False,False,False,True ,True , -- **        **
         True ,True ,True ,False,False,False,False,False,False,True ,True ,True , -- ***      ***
         False,True ,True ,False,False,False,False,False,False,True ,True ,False, --  **      ** 
         False,True ,True ,True ,False,False,False,False,True ,True ,True ,False, --  ***    *** 
         False,False,True ,True ,True ,True ,True ,True ,True ,True ,False,False, --   ********  
         False,False,False,False,True ,True ,True ,True ,False,False,False,False, --     ****    
         -- codepoint 0X37
         True ,True ,True ,True ,True ,True ,True ,True ,True ,True ,True ,True , -- ************
         True ,True ,True ,True ,True ,True ,True ,True ,True ,True ,True ,True , -- ************
         False,False,False,False,False,False,False,False,False,False,True ,True , --           **
         False,False,False,False,False,False,False,False,False,True ,True ,False, --          ** 
         False,False,False,False,False,False,False,False,True ,True ,False,False, --         **  
         False,False,False,False,False,False,False,False,True ,True ,False,False, --         **  
         False,False,False,False,False,False,False,True ,True ,False,False,False, --        **   
         False,False,False,False,False,False,True ,True ,False,False,False,False, --       **    
         False,False,False,False,False,False,True ,True ,False,False,False,False, --       **    
         False,False,False,False,False,True ,True ,False,False,False,False,False, --      **     
         False,False,False,False,False,True ,True ,False,False,False,False,False, --      **     
         False,False,False,False,True ,True ,True ,False,False,False,False,False, --     ***     
         False,False,False,False,True ,True ,False,False,False,False,False,False, --     **      
         False,False,False,False,True ,True ,False,False,False,False,False,False, --     **      
         False,False,False,True ,True ,True ,False,False,False,False,False,False, --    ***      
         False,False,False,True ,True ,False,False,False,False,False,False,False, --    **       
         False,False,False,True ,True ,False,False,False,False,False,False,False, --    **       
         False,False,False,True ,True ,False,False,False,False,False,False,False, --    **       
         -- codepoint 0X38
         False,False,False,True ,True ,True ,True ,True ,False,False,False,False, --    *****    
         False,False,True ,True ,True ,True ,True ,True ,True ,True ,False,False, --   ********  
         False,True ,True ,True ,False,False,False,False,True ,True ,True ,False, --  ***    *** 
         False,True ,True ,False,False,False,False,False,False,True ,True ,False, --  **      ** 
         False,True ,True ,False,False,False,False,False,False,True ,True ,False, --  **      ** 
         False,True ,True ,False,False,False,False,False,False,True ,True ,False, --  **      ** 
         False,True ,True ,True ,False,False,False,False,True ,True ,True ,False, --  ***    *** 
         False,False,True ,True ,True ,True ,True ,True ,True ,True ,False,False, --   ********  
         False,False,True ,True ,True ,True ,True ,True ,True ,True ,False,False, --   ********  
         False,True ,True ,True ,False,False,False,False,True ,True ,True ,False, --  ***    *** 
         True ,True ,True ,False,False,False,False,False,False,True ,True ,False, -- ***      ** 
         True ,True ,False,False,False,False,False,False,False,True ,True ,True , -- **       ***
         True ,True ,False,False,False,False,False,False,False,False,True ,True , -- **        **
         True ,True ,False,False,False,False,False,False,False,True ,True ,True , -- **       ***
         True ,True ,True ,False,False,False,False,False,False,True ,True ,False, -- ***      ** 
         False,True ,True ,True ,False,False,False,False,True ,True ,True ,False, --  ***    *** 
         False,False,True ,True ,True ,True ,True ,True ,True ,True ,False,False, --   ********  
         False,False,False,True ,True ,True ,True ,True ,False,False,False,False, --    *****    
         -- codepoint 0X39
         False,False,False,True ,True ,True ,True ,True ,False,False,False,False, --    *****    
         False,False,True ,True ,True ,True ,True ,True ,True ,True ,False,False, --   ********  
         False,True ,True ,True ,False,False,False,False,True ,True ,True ,False, --  ***    *** 
         True ,True ,True ,False,False,False,False,False,False,True ,True ,False, -- ***      ** 
         True ,True ,False,False,False,False,False,False,False,True ,True ,False, -- **       ** 
         True ,True ,False,False,False,False,False,False,False,True ,True ,True , -- **       ***
         True ,True ,False,False,False,False,False,False,False,True ,True ,True , -- **       ***
         True ,True ,True ,False,False,False,False,False,False,True ,True ,True , -- ***      ***
         False,True ,True ,True ,False,False,False,False,True ,True ,True ,True , --  ***    ****
         False,True ,True ,True ,True ,True ,True ,True ,True ,True ,True ,True , --  ***********
         False,False,False,True ,True ,True ,True ,True ,False,True ,True ,True , --    ***** ***
         False,False,False,False,False,False,False,False,False,True ,True ,False, --          ** 
         False,False,False,False,False,False,False,False,False,True ,True ,False, --          ** 
         True ,True ,True ,False,False,False,False,False,False,True ,True ,False, -- ***      ** 
         False,True ,True ,False,False,False,False,False,True ,True ,True ,False, --  **     *** 
         False,True ,True ,True ,False,False,False,True ,True ,True ,False,False, --  ***   ***  
         False,False,True ,True ,True ,True ,True ,True ,True ,False,False,False, --   *******   
         False,False,False,True ,True ,True ,True ,True ,False,False,False,False  --    *****    
        );
end;
