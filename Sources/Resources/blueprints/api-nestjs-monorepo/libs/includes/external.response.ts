import { BadRequestException as BRE, HttpException } from '@nestjs/common';
import { InternalResponse } from 'libs/includes/internal.response';

export const CommandOkResponse = {
      appCode: 2001,
      statusCode: 200,
      status: 'Success',
      message: 'Operation successfull!!',
    };

export const QueryOkResponse = {
      appCode: 2000,
      statusCode: 200,
      status: 'Success',
      message: 'Data Found!!',
    };

export class ExternalResponse {

    static async query(response: InternalResponse) {
    if (response?.result) {
      return await ExternalResponse.queryOk(response?.result);
    } else if (response?.error?.statusCode === 400) {
      return await ExternalResponse.badRequest(response?.error?.message);
    } else if (response?.isEmptyData === true) {
      return await ExternalResponse.emptyData();
    } else {
      return await ExternalResponse.failure(response?.error);
    }
  }

  static async command(response: InternalResponse, data = false) {
    if (response?.result) {
      return await ExternalResponse.commandOk(response?.result, data);
    } else if (response?.error?.statusCode === 400) {
      return await ExternalResponse.badRequest(response?.error?.message);
    } else if (response?.isEmptyData === true) {
      return await ExternalResponse.emptyData();
    } else {
      return await ExternalResponse.failure(response?.error);
    }
  }

  static async badRequest(message: string) {
    throw new BadRequestException(message);
  }

  static async emptyData() {
    const dataRes = {
      appCode: 2000,
      statusCode: 200,
      status: 'Success',
      data: [],
    };
    throw new Success(dataRes);
  }

  static async commandOk(response: any, data: boolean) {
    const dataRes = CommandOkResponse

    if (data && response) dataRes['data'] = response;
    throw new Success(dataRes);
  }

  static async queryOk(response: any) {
    const dataRes = QueryOkResponse

    if (response?.totalCount) {
      dataRes['totalCount'] = response?.totalCount;
      dataRes['data'] = response?.data;
    } else {
      dataRes['data'] = response;
    }

    throw new Success(dataRes);
  }

  static async failure(error: any) {
    if (error?.message?.startsWith('E11000')) {
      error.message = 'Duplicate Entry detected!!';
      error.statusCode = 409; //Conflict
    }

    throw new FailureException(error);
  }


}

export class BadRequestException extends BRE {
  constructor(value: string = 'Invalid Request!') {
    super({
      appCode: 4000,
      statusCode: 400,
      status: 'Invalid',
      error: value,
    });
  }
}

export class FailureException extends HttpException {
  constructor(error: any) {
    super(
      {
        appCode: 5000,
        statusCode: error?.statusCode || 500,
        status: 'Failure',
        error: error?.message || 'Internal Server Error!!',
      },
      error?.statusCode || 500,
    );
  }
}

export class Success extends HttpException {
  constructor(response: any) {
    super(response, response.statusCode);
  }
}