CLASS zcl_mex_inf2_folio DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_sadl_exit_calc_element_read.

  PRIVATE SECTION.
    CONSTANTS:
      c_entity TYPE string VALUE `ZC_MEXINFORME2`,
      c_folio  TYPE string VALUE `NUEVOFOLIOFISCAL`.
ENDCLASS.



CLASS zcl_mex_inf2_folio IMPLEMENTATION.

  METHOD if_sadl_exit_calc_element_read~get_calculation_info.
    " Campos que necesita el cálculo aunque el usuario no los muestre
    IF iv_entity <> c_entity.
      RETURN.
    ENDIF.

    IF line_exists( it_requested_calc_elements[ table_line = c_folio ] ).
      INSERT `SOCIEDAD`        INTO TABLE et_requested_orig_elements.
      INSERT `NUMERODOCUMENTO` INTO TABLE et_requested_orig_elements.
      INSERT `EJERCICIO`       INTO TABLE et_requested_orig_elements.
    ENDIF.
  ENDMETHOD.


  METHOD if_sadl_exit_calc_element_read~calculate.
    TYPES: BEGIN OF ty_folio,
             tdname TYPE tdobname,
             folio  TYPE c LENGTH 255,
           END OF ty_folio.

    DATA: lt_names  TYPE SORTED TABLE OF tdobname WITH UNIQUE KEY table_line,
          lt_folios TYPE HASHED TABLE OF ty_folio WITH UNIQUE KEY tdname,
          lt_lines  TYPE STANDARD TABLE OF tline,
          lv_name   TYPE tdobname,
          lv_folio  TYPE string.

    FIELD-SYMBOLS: <ls_orig>  TYPE any,
                   <ls_calc>  TYPE any,
                   <lv_bukrs> TYPE any,
                   <lv_belnr> TYPE any,
                   <lv_gjahr> TYPE any,
                   <lv_folio> TYPE any.

    IF NOT line_exists( it_requested_calc_elements[ table_line = c_folio ] ).
      RETURN.
    ENDIF.

    " 1. Nombres de texto de las filas recibidas (BUKRS + BELNR + GJAHR)
    LOOP AT it_original_data ASSIGNING <ls_orig>.
      ASSIGN COMPONENT `SOCIEDAD`        OF STRUCTURE <ls_orig> TO <lv_bukrs>.
      ASSIGN COMPONENT `NUMERODOCUMENTO` OF STRUCTURE <ls_orig> TO <lv_belnr>.
      ASSIGN COMPONENT `EJERCICIO`       OF STRUCTURE <ls_orig> TO <lv_gjahr>.
      IF <lv_bukrs> IS ASSIGNED AND <lv_belnr> IS ASSIGNED AND <lv_gjahr> IS ASSIGNED.
        lv_name = |{ <lv_bukrs> }{ <lv_belnr> }{ <lv_gjahr> }|.
        INSERT lv_name INTO TABLE lt_names.
      ENDIF.
      UNASSIGN: <lv_bukrs>, <lv_belnr>, <lv_gjahr>.
    ENDLOOP.

    IF lt_names IS INITIAL.
      RETURN.
    ENDIF.

    " 2. Solo se llama READ_TEXT para los documentos que tienen el texto
    SELECT tdname
      FROM stxh
      FOR ALL ENTRIES IN @lt_names
      WHERE tdobject = 'BELEG'
        AND tdname   = @lt_names-table_line
        AND tdid     = 'YUUD'
        AND tdspras  = @sy-langu
      INTO TABLE @DATA(lt_stxh).

    LOOP AT lt_stxh INTO DATA(ls_stxh).
      CLEAR: lt_lines, lv_folio.

      CALL FUNCTION 'READ_TEXT'
        EXPORTING
          id       = 'YUUD'
          language = sy-langu
          name     = ls_stxh-tdname
          object   = 'BELEG'
        TABLES
          lines    = lt_lines
        EXCEPTIONS
          OTHERS   = 1.

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      LOOP AT lt_lines INTO DATA(ls_line).
        lv_folio = COND #( WHEN lv_folio IS INITIAL THEN ls_line-tdline
                           ELSE |{ lv_folio }{ ls_line-tdline }| ).
      ENDLOOP.

      INSERT VALUE #( tdname = ls_stxh-tdname folio = lv_folio ) INTO TABLE lt_folios.
    ENDLOOP.

    " 3. Llenar el campo calculado (misma posición que en IT_ORIGINAL_DATA)
    LOOP AT it_original_data ASSIGNING <ls_orig>.
      DATA(lv_tabix) = sy-tabix.

      READ TABLE ct_calculated_data ASSIGNING <ls_calc> INDEX lv_tabix.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      ASSIGN COMPONENT c_folio           OF STRUCTURE <ls_calc> TO <lv_folio>.
      ASSIGN COMPONENT `SOCIEDAD`        OF STRUCTURE <ls_orig> TO <lv_bukrs>.
      ASSIGN COMPONENT `NUMERODOCUMENTO` OF STRUCTURE <ls_orig> TO <lv_belnr>.
      ASSIGN COMPONENT `EJERCICIO`       OF STRUCTURE <ls_orig> TO <lv_gjahr>.

      IF <lv_folio> IS ASSIGNED AND <lv_bukrs> IS ASSIGNED
         AND <lv_belnr> IS ASSIGNED AND <lv_gjahr> IS ASSIGNED.
        lv_name = |{ <lv_bukrs> }{ <lv_belnr> }{ <lv_gjahr> }|.
        READ TABLE lt_folios ASSIGNING FIELD-SYMBOL(<ls_folio>) WITH TABLE KEY tdname = lv_name.
        IF sy-subrc = 0.
          <lv_folio> = <ls_folio>-folio.
        ENDIF.
      ENDIF.

      UNASSIGN: <lv_folio>, <lv_bukrs>, <lv_belnr>, <lv_gjahr>.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
