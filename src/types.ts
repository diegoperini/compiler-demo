import * as PT from './primitive-types'
import * as ST from './structured-types'

export type TypeT = ST.TypeT

export let T = {
  ...ST,
  ...PT
}
