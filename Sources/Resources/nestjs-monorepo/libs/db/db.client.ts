import { Collection, Db, MongoClient, ObjectId, ServerApiVersion } from 'mongodb';
import { UserSessionJwt } from 'libs/auth/auth.token';
import { InternalResponse } from 'libs/includes/internal.response';
import { Audit } from 'libs/includes/audit';

export class DBClient {
  constructor(public readonly token?: UserSessionJwt) {}
  
  private collection!: Collection<Document>;
  private client!: MongoClient;
  private db!: Db;

  async connect(collectionName: string) {
    const uri = process.env.DATABASE_URL;
    const dbName = process.env.DATABASE_NAME;

    if (!uri || !dbName) {
      throw new Error('DATABASE_URL and DATABASE_NAME must be set');
    }

    this.client = new MongoClient(uri, {
      monitorCommands: true,
      serverApi: {
        version: ServerApiVersion.v1,
        strict: true,
        deprecationErrors: true,
      },
    });

    await this.client.connect();
    this.db = this.client.db(dbName);
    this.collection = this.db.collection(collectionName);
  }

  async useCollection(collectionName: string) {
    this.collection = this.db.collection(collectionName);
  }

  async insert(payload: any): Promise<InternalResponse> {
    let response: InternalResponse;
    try {
      const audit = new Audit();
      audit.crBy = this.token?.getUserRef();
      audit.crDt = new Date();
      audit.upDt = new Date();
      audit.upBy = this.token.getUserRef();
      audit.del = false;

      const payloadToInsert = {
        ...payload,
        audit: audit,
      };

      const insertResponse = await this.collection.insertOne(payloadToInsert);
      response = InternalResponse.result(insertResponse);
    } catch (error) {
      response = InternalResponse.exception(error);
    }
    return response;
  }

  async update({ id, payload }: { id: string; payload: any }): Promise<InternalResponse> {
    let response: InternalResponse;
    try {
      const getData = await this.findById(id);
      if (!getData?.result?._id) { return InternalResponse.noData(); }

      const audit = new Audit();
      audit.upBy = this.token.getUserRef();
      audit.upDt = new Date();

      const upDtPayload = {
        ...payload,
        'audit.upDt': audit.upDt,
        'audit.upBy': audit.upBy,
      };

      if (upDtPayload._id) {
        delete upDtPayload._id;
      }

      const updateResponse = await this.collection.updateOne({ _id: new ObjectId(id) }, { $set: { ...upDtPayload } });

      if (updateResponse?.matchedCount) {
        response = InternalResponse.success();
      } else {
        response = InternalResponse.noData();
      }

    } catch (error) {
      response = InternalResponse.exception(error);
    }

    return response;
  }

  async updatebyQuery({
    query,
    payload,
  }: {
    query: Map<string, any>;
    payload: Map<string, any>;
  }): Promise<InternalResponse> {
    let response: InternalResponse;
    try {
      const formattedQuery = {
        ...Object.fromEntries(query),
      };

      const audit = new Audit();
      audit.upBy = this.token.getUserRef();
      audit.upDt = new Date();

      const upDtPayload = {
        $set: {
          ...Object.fromEntries(payload),
          'audit.upDt': audit.upDt,
          'audit.upBy': audit.upBy,
        },
      };

      const updateResponse = await this.collection.updateMany(formattedQuery, upDtPayload);

      if (updateResponse?.matchedCount) {
        response = InternalResponse.success();
      } else {
        response = InternalResponse.noData();
      }
    } catch (error) {
      response = InternalResponse.exception(error);
    }

    return response;
  }


  async softDelete(id: string): Promise<InternalResponse> {
    let response: InternalResponse;
    try {
      const getData = await this.findById(id);
      if (!getData?.result?._id) { return InternalResponse.noData(); }

      const audit = new Audit();
      audit.upBy = this.token.getUserRef();
      audit.upDt = new Date();
      const upDtPayload = {
        'audit.upDt': audit.upDt,
        'audit.upBy': audit.upBy,
        'audit.del': true,
      };
      const updateResponse = await this.collection.updateOne({ _id: new ObjectId(id) }, { $set: { ...upDtPayload } });

      if (updateResponse?.matchedCount) {
        response = InternalResponse.success();
      } else {
        response = InternalResponse.noData();
      }

    } catch (error) {
      response = InternalResponse.exception(error);
    }

    return response;
  }

  async totalActiveCount(): Promise<InternalResponse> {
    let response: InternalResponse;
    try {
      const countPipeline = [
        {
          $match: {
            'audit.del': false,
          },
        },
        { $count: 'total_count' },
      ];

      const countResponse = await this.collection.aggregate(countPipeline).toArray();
      response = InternalResponse.result(countResponse[0].total_count);
    } catch (error) {
      response = InternalResponse.exception(error);
    }

    return response;
  }

  async queryBasedCount(query: Map<string, any>): Promise<InternalResponse> {
    let response: InternalResponse;
    try {
      const formattedQuery = {
        ...Object.fromEntries(query),
      };

      const countResponse = await this.collection.countDocuments(formattedQuery);
      response = InternalResponse.result(countResponse);
    } catch (error) {
      response = InternalResponse.exception(error);
    }

    return response;
  }

  async findById(id: string, removeAudit: boolean = true): Promise<InternalResponse> {
    let response: InternalResponse;
    try {
      const result = await this.collection.findOne({
        _id: new ObjectId(id),
        'audit.del': false,
      });

      if (!result?._id) { return InternalResponse.noData(); }

      const resp: any = result;
      if (removeAudit === true) {
        delete resp?.audit;
      }
      response = InternalResponse.result(resp);

    } catch (error) {
      response = InternalResponse.exception(error);
    }

    return response;
  }

  async findAllByPage({
    page,
    limit,
    query,
    removeAudit = true,
  }: {
    page: number;
    limit: number;
    query: Map<string, any>;
    removeAudit?: boolean;
  }): Promise<InternalResponse> {
    let result: any;
    let count: any;
    let response: InternalResponse;
    try {

      const formattedQuery = {
        ...Object.fromEntries(query),
        'audit.del': false,
      };

      const skipCount = (page - 1) * limit;
      
      const dataResponse = await this.collection
        .find(formattedQuery)
        .sort({ 'audit.upDt': -1 })
        .skip(skipCount)
        .limit(limit)
        .toArray();

      if (!dataResponse?.length) { return InternalResponse.noData(); }

      result = dataResponse;
      result.map((item: any) => {
        if (removeAudit === true) {
          delete item?.audit;
        }
      });

      count = await this.collection.countDocuments(formattedQuery);
      response = InternalResponse.result({ totalCount: count, data: result });

    } catch (error) {
      response = InternalResponse.exception(error);
    }

    return response;
  }

  async batchedGetByIds(ids: Set<string>): Promise<InternalResponse> {
    let response: InternalResponse;

    try {
      const targetIds = [...ids].map(id => new ObjectId(id));

      const formattedQuery = {
        _id: { $in: targetIds },
        'audit.del': false,
      };
      const dataResponse = await this.collection.find(formattedQuery).toArray();

      if (!dataResponse?.length) { return InternalResponse.noData(); }

      const resp: any = dataResponse;
      resp.map((item: any) => {
        delete item?.audit;
      });
      response = InternalResponse.result(resp);

    } catch (error) {
      response = InternalResponse.exception(error);
    }

    return response;
  }

  async findByQuery(query: Map<string, any>): Promise<InternalResponse> {
    let response: InternalResponse;
    try {
      const formattedQuery = {
        ...Object.fromEntries(query),
      };

      const pipeline = [
        {
          $match: {
            $and: [{ 'audit.del': false }, formattedQuery],
          },
        },
      ];

      const result = await this.collection.aggregate(pipeline).toArray();

      if (!result?.length) { return InternalResponse.noData(); }

      const resp: any = result;
      resp.map((item: any) => {
        delete item?.audit;
      });
      response = InternalResponse.result(resp);

    } catch (error) {
      response = InternalResponse.exception(error);
    }

    return response;
  }

  async activate(id: string): Promise<InternalResponse> {
    let response: InternalResponse;
    try {
      const audit = new Audit();
      audit.upBy = this.token.getUserRef();
      audit.upDt = new Date();
      const upDtPayload = {
        'audit.upDt': audit.upDt,
        'audit.upBy': audit.upBy,
        active: true,
      };

      const getData = await this.findById(id);
      if (!getData?.result?._id) { return InternalResponse.noData(); }

      const updateResponse = await this.collection.updateOne({ _id: new ObjectId(id) }, { $set: { ...upDtPayload } });

      if (updateResponse?.matchedCount) {
        response = InternalResponse.success();
      } else {
        response = InternalResponse.noData();
      }

    } catch (error) {
      response = InternalResponse.exception(error);
    }

    return response;
  }

  async deactivate(id: string): Promise<InternalResponse> {
    let response: InternalResponse;
    try {
      const audit = new Audit();
      audit.upBy = this.token.getUserRef();
      audit.upDt = new Date();
      const upDtPayload = {
        'audit.upDt': audit.upDt,
        'audit.upBy': audit.upBy,
        active: false,
      };
      const getData = await this.findById(id);
      if (!getData?.result?._id) { return InternalResponse.noData(); }

      const updateResponse = await this.collection.updateOne({ _id: new ObjectId(id) }, { $set: { ...upDtPayload } });

      if (updateResponse?.matchedCount) {
        response = InternalResponse.success();
      } else {
        response = InternalResponse.noData();
      }

    } catch (error) {
      response = InternalResponse.exception(error);
    }

    return response;
  }

  async hardDeleteOneByQuery({ query }: { query: Map<string, any> }): Promise<InternalResponse> {
    let response: InternalResponse;
    try {
      const formattedQuery = {
        ...Object.fromEntries(query),
      };

      const delResponse = await this.collection.deleteOne(formattedQuery);
      if (delResponse?.deletedCount) {
        response = InternalResponse.success();
      } else {
        response = InternalResponse.noData();
      }
    } catch (error) {
      response = InternalResponse.exception(error);
    }

    return response;
  }

  async hardDeleteOneById(_id: string): Promise<InternalResponse> {
    let response: InternalResponse;
    try {
      const targetIdToDelete = new ObjectId(_id);

      const delResponse = await this.collection.deleteOne({ _id: targetIdToDelete });
      if (delResponse?.deletedCount) {
        response = InternalResponse.success();
      } else {
        response = InternalResponse.noData();
      }
    } catch (error) {
      response = InternalResponse.exception(error);
    }

    return response;
  }

  async close() {
    if (this.client) {
      await this.client.close();
    }
  }

  async pingCheck() {
    return this.db.runCursorCommand({
      ping: 1,
    });
  }
}
