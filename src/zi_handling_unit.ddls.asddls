@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Handling Unit - Basic Interface View'
@Metadata.ignorePropagatedAnnotations: true
define view entity zi_handling_unit
  as select from vekp as HandlingUnit
    inner join   vepo as _Item on _Item.venum = HandlingUnit.venum
  association to parent zi_outbound_delivery as _Delivery on $projection.HUObject = _Delivery.DeliveryNumber
{

  key HandlingUnit.venum    as HandlingUnitNumber,
      HandlingUnit.exidv    as ExternalHandlingUnitID,
      HandlingUnit.exidv2   as HandlingUnitDescription,
      HandlingUnit.vhilm    as PackagingMaterial,
      HandlingUnit.vpobj    as PackingObject,
      HandlingUnit.vpobjkey as HUObject,
      @Semantics.quantity.unitOfMeasure: 'WeightUnit'
      HandlingUnit.brgew    as GrossWeight,
      HandlingUnit.gewei    as WeightUnit,
      @Semantics.quantity.unitOfMeasure: 'VolumeUnit'
      HandlingUnit.btvol    as Volume,
      HandlingUnit.voleh    as VolumeUnit,
      @Semantics.quantity.unitOfMeasure: 'WeightUnit'
      HandlingUnit.tarag    as TareWeight,

      // Link to the delivery this HU belongs to (via VEPO item table)
      _Item.vbeln           as DeliveryNumber,
      _Item.posnr           as DeliveryItem,
      _Item.matnr           as Material,
      @Semantics.quantity.unitOfMeasure: 'QuantityUnit'
      _Item.vemng           as Quantity,
      _Item.vemeh           as QuantityUnit,

      /* Associations */
      _Delivery

}
