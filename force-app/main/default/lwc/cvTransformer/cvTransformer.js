import { LightningElement, api, track, wire } from "lwc";
import candidateAttachCV from "@salesforce/apex/CVTransformerApi.candidateAttachCV";
import candidateContextGet from "@salesforce/apex/CVTransformerApi.candidateContextGet";
import candidateExportCV from "@salesforce/apex/CVTransformerApi.candidateExportCV";
import candidateLink from "@salesforce/apex/CVTransformerApi.candidateLink";
import candidateUnlink from "@salesforce/apex/CVTransformerApi.candidateUnlink";
import configUpdate from "@salesforce/apex/CVTransformerApi.configUpdate";
import configUpsert from "@salesforce/apex/CVTransformerApi.configUpsert";
import contactDataGet from "@salesforce/apex/CVTransformerApi.contactDataGet";
import contactTransformCv from "@salesforce/apex/CVTransformerApi.contactTransformCv";

export default class CVTransformer extends LightningElement {
  @api recordId;
  @track data = {};
  error;
  state = "loading";

  organization_id;
  candidate_id;
  candidate_secret_editable;

  external_candidate_data;
  iframe_ready = false;

  @wire(contactDataGet, { contact_id: "$recordId" })
  wiredData({ error, data }) {
    if (data) {
      this.data = data;
      this.error = null;
      this.state = this.data.organization_id ? "edit" : "setup";
    } else if (error) {
      this.data = {};
      this.error = error;
      this.state = "error";
    }
  }

  postIframeWhenReady() {
    if (!this.iframe_ready) return;
    const iframe = this.template.querySelector("iframe");
    if (!iframe || !iframe.contentWindow) return;

    iframe.contentWindow.postMessage(
      {
        avatar: null,
        id: this.recordId,
        name: "",
        type: "external-candidate-data",
        url: window.location.href,
        values: this.external_candidate_data
      },
      this.iframeUrl
    );
  }

  @wire(candidateContextGet, { contact_id: "$recordId" })
  wiredContext({ data }) {
    if (!data) return;
    try {
      this.external_candidate_data = JSON.parse(data);
      this.postIframeWhenReady();
    } catch (error) {
      console.log(error);
    }
  }

  get isLoading() {
    return this.state === "loading";
  }

  get isEdit() {
    return this.state === "edit";
  }

  get isSetup() {
    return this.state === "setup";
  }

  get isConfigure() {
    return this.state === "configure";
  }

  get isError() {
    return this.state === "error";
  }

  get iframeUrl() {
    let url = `https://www.cv-transformer.com/candidates/${this.data.candidate_id}?s=${this.data.candidate_secret}`;
    if (this.data.color_scheme)
      url += `&color_scheme=${this.data.color_scheme}`;
    if (this.data.language) url += `&language=${this.data.language}`;
    url += `&context=salesforce`;
    return url;
  }

  onConfigure() {
    this.error = null;
    this.state = "configure";
  }

  onConfigureCancel() {
    this.error = null;
    this.state = "edit";
  }

  onSetup() {
    this.error = null;
    this.state = "setup";
  }

  onSetupCancel() {
    this.error = null;
    this.state = "edit";
  }

  setError(error) {
    console.log(error);
    if (error.body && error.body.message) this.error = error.body.message;
    else if (error.message) this.error = error.message;
    else if (typeof error === "string") this.error = error;
    else if (error instanceof Error) this.error = error.toString();
    else this.error = "An unknown error occurred.";
  }

  async onSetupSubmit(event) {
    event.preventDefault();
    this.state = "loading";
    try {
      const inputs = [...this.template.querySelectorAll("lightning-input")];
      const values = Object.fromEntries(
        inputs.map((input) => [input.name, input.value])
      );
      const organization_id = await configUpsert({ api_key: values.api_key });
      this.data = { ...this.data, organization_id };
      this.error = null;
      this.state = "edit";
    } catch (error) {
      this.data = {};
      this.setError(error);
      this.state = "setup";
    }
  }

  get languageWithDefault() {
    return this.data.language || "en";
  }
  languageOptions = [
    { label: "English", value: "en" },
    { label: "Deutsch", value: "de" },
    { label: "Français", value: "fr" },
    { label: "Nederlands", value: "nl" }
  ];
  async onLanguageChange(event) {
    const language = event.detail.value;
    this.state = "loading";
    try {
      await configUpdate({ color_schema: this.data.color_schema, language });
      this.data = { ...this.data, language };
      this.error = null;
    } catch (error) {
      this.setError(error);
    }
    this.state = "configure";
  }

  get colorSchemeWithDefault() {
    return this.data.color_scheme || "";
  }
  colorSchemeOptions = [
    { label: "System default", value: "" },
    { label: "Light", value: "light" },
    { label: "Dark", value: "dark" }
  ];
  async onColorSchemeChange(event) {
    const color_scheme = event.detail.value;
    this.state = "loading";
    try {
      await configUpdate({ color_scheme, language: this.data.language });
      this.data = { ...this.data, color_scheme };
      this.error = null;
    } catch (error) {
      this.setError(error);
    }
    this.state = "configure";
  }

  async onCandidateCreate() {
    this.state = "loading";
    try {
      this.data = await contactTransformCv({ contact_id: this.recordId });
      this.error = null;
    } catch (error) {
      this.setError(error);
    }
    this.state = "edit";
  }

  async onCandidateSelect() {
    // eslint-disable-next-line no-alert
    const candidate_id_or_url = prompt(
      "Enter CV-Transformer candidate ID or URL"
    );
    let candidate_id = "";
    try {
      const url = new URL(candidate_id_or_url);
      candidate_id = url.pathname.split("/").pop();
    } catch {
      candidate_id = candidate_id_or_url;
    }
    if (!candidate_id) return;
    this.state = "loading";
    try {
      this.data = await candidateLink({
        candidate_id,
        contact_id: this.recordId
      });
      this.error = null;
    } catch (error) {
      this.setError(error);
    }
    this.state = "edit";
  }

  async onCandidateUnlink() {
    this.state = "loading";
    try {
      await candidateUnlink({ contact_id: this.recordId });
      this.data = { ...this.data, candidate_id: null, candidate_secret: null };
      this.error = null;
    } catch (error) {
      this.setError(error);
    }
    this.state = "edit";
  }

  async onAttachmentSelect(event) {
    this.state = "loading";
    try {
      if (event.detail === "regular" || event.detail === "anonymous") {
        await candidateExportCV({
          contact_id: this.recordId,
          export_type: event.detail
        });
        window.location.reload();
      } else
        await candidateAttachCV({
          contact_id: this.recordId,
          content_version_id: event.detail
        });
    } catch (error) {
      this.setError(error);
    }
    this.state = "edit";
  }

  async onMessage(event) {
    if (
      typeof event.data !== "object" ||
      event.data === null ||
      Array.isArray(event.data)
    )
      return;
    if (
      event.data.type === "candidate-export" &&
      typeof event.data.export_type === "string"
    ) {
      this.state = "loading";
      try {
        await candidateExportCV({
          contact_id: this.recordId,
          export_type: event.data.export_type
        });
        window.location.reload();
      } catch (error) {
        this.setError(error);
      }
      this.state = "edit";
    }

    if (event.data.type === "iframe-ready") {
      this.iframe_ready = true;
      this.postIframeWhenReady();
    }
  }

  connectedCallback() {
    if (!this.boundOnMessage) this.boundOnMessage = this.onMessage.bind(this);
    window.addEventListener("message", this.boundOnMessage);
  }

  disconnectedCallback() {
    if (this.boundOnMessage)
      window.removeEventListener("message", this.boundOnMessage);
  }
}
