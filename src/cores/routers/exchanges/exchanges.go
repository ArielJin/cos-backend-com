package exchanges

import (
	"cos-backend-com/src/common/flake"
	"cos-backend-com/src/common/validate"
	"cos-backend-com/src/cores/routers"
	"cos-backend-com/src/libs/apierror"
	"cos-backend-com/src/libs/models/exchangemodels"
	"cos-backend-com/src/libs/models/startupmodels"
	"cos-backend-com/src/libs/sdk/cores"
	"github.com/wujiu2020/strip/utils/apires"
	"net/http"
	"time"
)

type ExchangesHandler struct {
	routers.Base
}

func (h *ExchangesHandler) CreateExchange(startupId flake.ID) (res interface{}) {
	var startup cores.StartUpResult
	if err := startupmodels.Startups.Get(h.Ctx, startupId, &startup); err != nil {
		h.Log.Warn(err)
		res = apierror.HandleError(err)
		return
	}

	var input cores.CreateExchangeInput
	if err := h.Params.BindJsonBody(&input); err != nil {
		h.Log.Warn(err)
		res = apierror.HandleError(err)
		return
	}
	input.StartupId = startup.Id
	input.TokenName1 = startup.Setting.TokenName
	input.TokenSymbol1 = startup.Setting.TokenSymbol
	input.TokenAddress1 = *startup.Setting.TokenAddr
	input.TokenDivider1 = 1
	input.TokenName2 = "ETH"
	input.TokenSymbol2 = "ETH"
	input.TokenAddress2 = ""
	input.TokenDivider2 = 1
	input.PairName = input.TokenName1 + "-" + input.TokenName2
	input.PairAddress = input.TxId
	input.Status = cores.ExchangeStatusPending

	if err := validate.Default.Struct(input); err != nil {
		h.Log.Warn(err)
		res = apierror.HandleError(err)
		return
	}

	var output cores.CreateExchangeResult
	if err := exchangemodels.Exchanges.CreateExchange(h.Ctx, &input, &output); err != nil {
		h.Log.Warn(err)
		res = apierror.HandleError(err)
		return
	}

	res = apires.With(&output, http.StatusOK)
	return
}

func (h *ExchangesHandler) GetExchange(id flake.ID) (res interface{}) {
	var input cores.GetExchangeInput
	input.Id = id
	var output cores.ExchangeResult
	if err := exchangemodels.Exchanges.GetExchange(h.Ctx, &input, &output); err != nil {
		h.Log.Warn(err)
		res = apierror.HandleError(err)
		return
	}

	res = apires.With(&output, http.StatusOK)
	return
}

func (h *ExchangesHandler) GetExchangeByStartup(id flake.ID) (res interface{}) {
	var input cores.GetExchangeInput
	input.StartupId = id
	var output cores.ExchangeResult
	if err := exchangemodels.Exchanges.GetExchange(h.Ctx, &input, &output); err != nil {
		h.Log.Warn(err)
		res = apierror.HandleError(err)
		return
	}

	res = apires.With(&output, http.StatusOK)
	return
}

func (h *ExchangesHandler) ListExchanges() (res interface{}) {
	var params cores.ListExchangesInput
	h.Params.BindValuesToStruct(&params)

	if err := validate.Default.Struct(params); err != nil {
		h.Log.Warn(err)
		res = apierror.HandleError(err)
		return
	}

	var output cores.ListExchangesResult
	total, err := exchangemodels.Exchanges.ListExchanges(h.Ctx, &params, &output.Result)
	if err != nil {
		h.Log.Warn(err)
		res = apierror.HandleError(err)
		return
	}
	output.Total = total

	res = apires.With(&output, http.StatusOK)
	return
}

func (h *ExchangesHandler) CreateExchangeTx(exchangeId flake.ID) (res interface{}) {
	var input cores.CreateExchangeTxInput
	if err := h.Params.BindJsonBody(&input); err != nil {
		h.Log.Warn(err)
		res = apierror.HandleError(err)
		return
	}
	input.ExchangeId = exchangeId
	input.Status = cores.ExchangeTxStatusPending
	if input.TokenAmount1 == 0 {
		input.PricePerToken1 = 0
	} else {
		input.PricePerToken1 = input.TokenAmount2 / input.TokenAmount1
	}
	if input.TokenAmount2 == 0 {
		input.PricePerToken2 = 0
	} else {
		input.PricePerToken2 = input.TokenAmount1 / input.TokenAmount2
	}
	input.OccuredAt = time.Now().Format("2006-01-02 15:04:05")

	if err := validate.Default.Struct(input); err != nil {
		h.Log.Warn(err)
		res = apierror.HandleError(err)
		return
	}

	var output cores.CreateExchangeTxResult
	if err := exchangemodels.Exchanges.CreateExchangeTx(h.Ctx, &input, &output); err != nil {
		h.Log.Warn(err)
		res = apierror.HandleError(err)
		return
	}

	res = apires.With(&output, http.StatusOK)
	return
}

func (h *ExchangesHandler) GetExchangeTx(id flake.ID) (res interface{}) {
	var input cores.GetExchangeTxInput
	input.Id = id
	var output cores.ExchangeTxResult
	if err := exchangemodels.Exchanges.GetExchangeTx(h.Ctx, &input, &output); err != nil {
		h.Log.Warn(err)
		res = apierror.HandleError(err)
		return
	}

	res = apires.With(&output, http.StatusOK)
	return
}

func (h *ExchangesHandler) GetExchangeAllStatsTotal() (res interface{}) {
	var output cores.ExchangeAllStatsTotalResult
	if err := exchangemodels.Exchanges.GetExchangeAllStatsTotal(h.Ctx, &output); err != nil {
		h.Log.Warn(err)
		res = apierror.HandleError(err)
		return
	}

	res = apires.With(&output, http.StatusOK)
	return
}

func (h *ExchangesHandler) GetExchangeOneStatsTotal(exchangeId flake.ID) (res interface{}) {
	var input cores.ExchangeOneStatsInput
	input.Id = exchangeId
	var output cores.ExchangeOneStatsTotalResult
	if err := exchangemodels.Exchanges.GetExchangeOneStatsTotal(h.Ctx, &input, &output); err != nil {
		h.Log.Warn(err)
		res = apierror.HandleError(err)
		return
	}

	res = apires.With(&output, http.StatusOK)
	return
}

func (h *ExchangesHandler) GetExchangeOneStatsPriceChange(exchangeId flake.ID) (res interface{}) {
	var input cores.ExchangeOneStatsInput
	input.Id = exchangeId
	var output cores.ExchangeOneStatsPriceChangeResult
	if err := exchangemodels.Exchanges.GetExchangeOneStatsPriceChange(h.Ctx, &input, &output); err != nil {
		h.Log.Warn(err)
		res = apierror.HandleError(err)
		return
	}

	res = apires.With(&output, http.StatusOK)
	return
}
