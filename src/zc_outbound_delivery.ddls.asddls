@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Outbound delivery - Consumption View'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

@UI: {
    headerInfo: {
        typeName: 'Delivery',
        typeNamePlural: 'Deliveries',
        title: { type: #STANDARD, value: 'DeliveryNumber' }
    }
}

define root view entity zc_outbound_delivery
  provider contract transactional_query
  as projection on zi_outbound_delivery as Delivery
{
  key DeliveryNumber, 
      DeliveryType,
      ShipToParty,
      DeliveryDate,
      @Semantics.quantity.unitOfMeasure: 'WeightUnit'
      TotalWeight,
      WeightUnit,
      @Semantics.quantity.unitOfMeasure: 'VolumeUnit'
      TotalVolume,
      VolumeUnit,
      ActualGoodsMovementDate,
      GoodsMovementStatus,
      PickingStatus,
      PackingStatus,

      /* Associations */
      _HandlingUnit : redirected to composition child zc_handling_units 
}
