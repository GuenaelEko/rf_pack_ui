@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Outbound delivery - Basic Interface View'
@Metadata.ignorePropagatedAnnotations: true
define root view entity zi_outbound_delivery
  as select from likp
  composition[0..*] of zi_handling_unit as _HandlingUnit   
{
  key likp.vbeln     as DeliveryNumber, 
      likp.lfart as DeliveryType,
      likp.kunnr     as ShipToParty,
      likp.lfdat     as DeliveryDate,
      @Semantics.quantity.unitOfMeasure: 'WeightUnit'
      likp.btgew as TotalWeight,
      likp.gewei as WeightUnit,
      @Semantics.quantity.unitOfMeasure: 'VolumeUnit'
      likp.volum as TotalVolume,
      likp.voleh as VolumeUnit,
      likp.wadat_ist as ActualGoodsMovementDate,
      likp.wbstk     as GoodsMovementStatus,
      likp.kostk     as PickingStatus,
      likp.pkstk     as PackingStatus,

      // Association
      _HandlingUnit

}
