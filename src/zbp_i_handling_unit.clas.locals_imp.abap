CLASS lhc__Delivery DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR _Delivery RESULT result.

    METHODS read FOR READ
      IMPORTING keys FOR READ _Delivery RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK _Delivery.

    METHODS rba_Handlingunit FOR READ
      IMPORTING keys_rba FOR READ _Delivery\_Handlingunit FULL result_requested RESULT result LINK association_links.

    METHODS cba_Handlingunit FOR MODIFY
      IMPORTING entities_cba FOR CREATE _Delivery\_Handlingunit.

ENDCLASS.

CLASS lhc__Delivery IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD read.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD rba_Handlingunit.
  ENDMETHOD.

  METHOD cba_Handlingunit.
  ENDMETHOD.

ENDCLASS.

CLASS lhc__HandlingUnit DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE _HandlingUnit.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE _HandlingUnit.

    METHODS read FOR READ
      IMPORTING keys FOR READ _HandlingUnit RESULT result.

    METHODS rba_Delivery FOR READ
      IMPORTING keys_rba FOR READ _HandlingUnit\_Delivery FULL result_requested RESULT result LINK association_links.

ENDCLASS.

CLASS lhc__HandlingUnit IMPLEMENTATION.

  METHOD create.
    " ----------------------------------------------------------------
    " For each entity to create:
    "   1. BAPI_HU_CREATE          → creates an HU (gets back EXIDV)
    "   2. BAPI_HU_CHANGE_HEADER   → assigns the HU to the delivery
    "   3. BAPI_TRANSACTION_COMMIT → commits both steps
    " ----------------------------------------------------------------
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_entity>).

      " --- Step 1: Create the HU ---
      DATA: ls_header_create TYPE bapihuhdrproposal,
            ls_header_return TYPE bapihuheader,
            lv_hu_exidv      TYPE bapihukey-hu_exid,
            lt_return        TYPE TABLE OF bapiret2.

      ls_header_create-pack_mat = <ls_entity>-PackagingMaterial.
      ls_header_create-ext_id_hu_2 = <ls_entity>-HandlingUnitDescription.

      CALL FUNCTION 'BAPI_HU_CREATE' DESTINATION 'NONE'
        EXPORTING
          headerproposal = ls_header_create
        IMPORTING
          huheader       = ls_header_return
          hukey          = lv_hu_exidv
        TABLES
          return         = lt_return.

      IF sy-subrc = 0.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' DESTINATION 'NONE'
          EXPORTING
            wait = 'X'.
      ENDIF.

      " Check for errors from BAPI_HU_CREATE
      DATA lv_error TYPE abap_bool VALUE abap_false.

      IF lt_return IS NOT INITIAL.
        LOOP AT lt_return ASSIGNING FIELD-SYMBOL(<ls_return>) WHERE type = 'A' OR type = 'E'.
          lv_error = abap_true.
          APPEND VALUE #(
              %cid = <ls_entity>-%cid
              %msg = new_message(
                  id        = <ls_return>-id
                  number    = <ls_return>-number
                  severity  = if_abap_behv_message=>severity-error
                  v1        = <ls_return>-message_v1
                  v2        = <ls_return>-message_v2
                  v3        = <ls_return>-message_v3
                  v4        = <ls_return>-message_v4 )
          ) TO reported-_handlingunit.
        ENDLOOP.

        IF lv_error = abap_true.
          APPEND VALUE #( %cid = <ls_entity>-%cid ) TO failed-_handlingunit.
          CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK' DESTINATION 'NONE'.
          CONTINUE.
        ENDIF.
      ENDIF.

      " --- Step 2: Assign the HU to the delivery ---
      ls_header_return-pack_mat_object = '01'.
      ls_header_return-pack_mat_obj_key = <ls_entity>-HUObject.

      CALL FUNCTION 'BAPI_HU_CHANGE_HEADER' DESTINATION 'NONE'
        EXPORTING
          hukey     = lv_hu_exidv
          huchanged = ls_header_return
        IMPORTING
          huheader  = ls_header_return
        TABLES
          return    = lt_return.

      lv_error = abap_false.
      IF lt_return IS NOT INITIAL.
        LOOP AT lt_return ASSIGNING <ls_return> WHERE type = 'E' OR type = 'A'.
          lv_error = abap_true.
          APPEND VALUE #(
            %cid = <ls_entity>-%cid
            %msg = new_message(
                     id       = <ls_return>-id
                     number   = <ls_return>-number
                     severity = if_abap_behv_message=>severity-error
                     v1       = <ls_return>-message_v1
                     v2       = <ls_return>-message_v2
                     v3       = <ls_return>-message_v3
                     v4       = <ls_return>-message_v4 )
          ) TO reported-_handlingunit.
        ENDLOOP.

        IF lv_error = abap_true.
          APPEND VALUE #( %cid = <ls_entity>-%cid ) TO failed-_handlingunit.
          CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK' DESTINATION 'NONE'.
          CONTINUE.
        ENDIF.
      ENDIF.

      " --- Step 3: Commit ---
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' DESTINATION 'NONE'
        EXPORTING
          wait = 'X'.

      " Map the newly created HU back to the caller
      APPEND VALUE #(
        %cid               = <ls_entity>-%cid
        HandlingUnitNumber = ls_header_return-hu_id
        "ExternalHandlingUnitID = ls_header_return-hu_exid
      ) TO mapped-_handlingunit.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    " ----------------------------------------------------------------
    " BAPI_HU_DELETE_FROM_DEL deletes a single HU from a delivery.
    " It requires the external HU ID (EXIDV) and the delivery number.
    " ----------------------------------------------------------------
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      DATA: lv_hu_to_delete TYPE bapihukey-hu_exid,
            lv_vbeln        TYPE likp-vbeln.

      " Retrieve external HU ID and delivery number from VEKP
      SELECT SINGLE exidv, vpobjkey
        FROM vekp
        WHERE venum = @<ls_key>-HandlingUnitNumber
        INTO @DATA(ls_vekp).

      IF sy-subrc <> 0.
        APPEND VALUE #(
          HandlingUnitNumber = <ls_key>-HandlingUnitNumber
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = |HU { <ls_key>-HandlingUnitNumber } not found| )
        ) TO reported-_handlingunit.
        APPEND VALUE #( HandlingUnitNumber = <ls_key>-HandlingUnitNumber )
          TO failed-_handlingunit.
        CONTINUE.
      ENDIF.

      DATA lt_return TYPE TABLE OF bapiret2.

      lv_hu_to_delete = |{ ls_vekp-exidv ALPHA = IN }|.
      lv_vbeln = ls_vekp-vpobjkey.


      CALL FUNCTION 'BAPI_HU_DELETE_FROM_DEL' DESTINATION 'NONE'
        EXPORTING
          delivery = lv_vbeln           " Delivery number
          hukey    = lv_hu_to_delete    " External HU ID
        TABLES
          return   = lt_return.


      " Check for errors
      DATA lv_error TYPE abap_bool VALUE abap_false.
      LOOP AT lt_return ASSIGNING FIELD-SYMBOL(<ls_return>)
        WHERE type = 'E' OR type = 'A'.
        lv_error = abap_true.
        APPEND VALUE #(
          HandlingUnitNumber = <ls_key>-HandlingUnitNumber
          %msg = new_message(
                   id       = <ls_return>-id
                   number   = <ls_return>-number
                   severity = if_abap_behv_message=>severity-error
                   v1       = <ls_return>-message_v1
                   v2       = <ls_return>-message_v2
                   v3       = <ls_return>-message_v3
                   v4       = <ls_return>-message_v4 )
        ) TO reported-_handlingunit.
      ENDLOOP.

      IF lv_error = abap_true.
        APPEND VALUE #( HandlingUnitNumber = <ls_key>-HandlingUnitNumber )
          TO failed-_handlingunit.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK' DESTINATION 'NONE'.
        CONTINUE.
      ENDIF.

      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' DESTINATION 'NONE'
        EXPORTING
          wait = 'X'.

      DELETE FROM vekp WHERE exidv = lv_hu_to_delete.

    ENDLOOP.
  ENDMETHOD.

  METHOD read.
    SELECT FROM vekp
        FIELDS venum    AS HandlingUnitNumber,
               exidv    AS ExternalHandlingUnitID,
               exidv2   AS HandlingUnitDescription,
               vhilm    AS PackagingMaterial,
               vpobj    AS PackingObject,
               vpobjkey AS HUObject,
               brgew    AS GrossWeight,
               gewei    AS WeightUnit,
               btvol    AS Volume,
               voleh    AS VolumeUnit,
               tarag    AS TareWeight
        FOR ALL ENTRIES IN @keys
        WHERE venum = @keys-HandlingUnitNumber
        INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDMETHOD.

  METHOD rba_Delivery.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZI_OUTBOUND_DELIVERY DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZI_OUTBOUND_DELIVERY IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
