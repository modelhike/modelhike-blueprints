import { Reference } from 'libs/domain-models/common.classes';

export class Audit {
  ver: string;
  crBy: Reference;
  crDt: Date;
  upDt: Date;
  upBy: Reference;
  srcId: string;
  srcApp: string;
  del: boolean;
}
